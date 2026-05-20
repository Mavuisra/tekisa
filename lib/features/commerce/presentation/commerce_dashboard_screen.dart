library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/business/business_category_profile.dart';
import '../../../core/config/env_config.dart';
import '../../../core/i18n/app_i18n.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/offline/tenant_context.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/datasources/salon_local_datasource.dart';
import '../../../data/models/commerce_models.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';
import '../../admin/presentation/admin_overview_screen.dart';
import '../../settings/presentation/commerce_settings_screen.dart';
import 'accounting_screen.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'insights_screen.dart';
import 'quick_sale_screen.dart';
import 'salon_service_screen.dart';
import 'supplier_network_screen.dart';

class CommerceDashboardScreen extends StatefulWidget {
  const CommerceDashboardScreen({super.key});

  @override
  State<CommerceDashboardScreen> createState() =>
      _CommerceDashboardScreenState();
}

class _CommerceDashboardScreenState extends State<CommerceDashboardScreen> {
  final _authLocal = AuthLocalDataSource();
  final _salonSource = SalonLocalDataSource();
  BusinessCategoryProfile _profile = BusinessCategoryProfiles.boutique;
  SalesSummaryModel? _summary;
  int _criticalStock = 0;
  int _inactiveCustomers = 0;
  String _topProduct = '—';
  bool _loading = true;
  int _notificationCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshNotificationCount();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshNotificationCount(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<CommerceRemoteDataSource?> _source() async {
    final token = await _authLocal.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final client = DioClient(
      baseUrl: EnvConfig.apiBaseUrl,
      accessToken: token,
      getRefreshToken: () => _authLocal.getRefreshToken(),
      saveAccessToken: (t) => _authLocal.setAccessToken(t),
    );
    return CommerceRemoteDataSource(client);
  }

  Future<void> _load() async {
    final user = _authLocal.getUser();
    final profile = BusinessCategoryProfiles.fromKey(user?.businessCategory);
    if (profile.key == 'salon_coiffure') {
      final tenant = TenantContext.current();
      if (tenant != null) {
        await _salonSource.ensureSeeded(tenant.tenantId);
        final stats = await _salonSource.getTodayStats(tenant.tenantId);
        if (!mounted) return;
        setState(() {
          _profile = profile;
          _summary = SalesSummaryModel(
            todayRevenue: stats.totalRevenue,
            transactions: stats.totalSales,
            averageTicket: stats.averageTicket,
          );
          _criticalStock = 0;
          _inactiveCustomers = 0;
          _topProduct = stats.topStylist == '—' ? '—' : stats.topStylist;
          _loading = false;
        });
      }
      return;
    }
    final source = await _source();
    if (source == null) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
      return;
    }
    try {
      final summary = await source.getSalesSummary();
      final stock = await source.getStockOverview();
      final customers = await source.getCustomersSummary();
      final insights = await source.getInsights();
      final critical = stock.where((s) => s.isCritical).length;
      final inactive = customers.where((c) {
        if (c.lastPurchaseAt == null) return true;
        final dt = DateTime.tryParse(c.lastPurchaseAt!);
        if (dt == null) return true;
        return DateTime.now().difference(dt).inDays >= 30;
      }).length;
      final topProduct = insights.topProducts.isNotEmpty
          ? insights.topProducts.first.name
          : '—';
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _summary = summary;
        _criticalStock = critical;
        _inactiveCustomers = inactive;
        _topProduct = topProduct;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshNotificationCount() async {
    final source = await _source();
    if (source == null || !mounted) return;
    final meId = int.tryParse(_authLocal.getUser()?.id ?? '');
    if (meId == null) return;
    try {
      final conversations = await source.getSupplierConversations();
      var unread = 0;
      for (final convo in conversations) {
        final messages = await source.getSupplierMessages(
          conversationId: convo.id,
        );
        if (messages.isEmpty) continue;
        final last = messages.last;
        if (last.senderId != meId) unread += 1;
      }
      if (!mounted) return;
      setState(() => _notificationCount = unread);
    } catch (_) {
      // En cas d'erreur réseau, on garde la dernière valeur affichée.
    }
  }

  Future<List<_UiNotification>> _loadNotifications() async {
    final source = await _source();
    final meId = int.tryParse(_authLocal.getUser()?.id ?? '');
    if (source == null || meId == null) return const <_UiNotification>[];

    final out = <_UiNotification>[];
    final conversations = await source.getSupplierConversations();
    for (final convo in conversations) {
      final messages = await source.getSupplierMessages(
        conversationId: convo.id,
      );
      if (messages.isEmpty) continue;
      final last = messages.last;
      out.add(
        _UiNotification(
          title: convo.supplierName,
          body: last.messageType == 'voice'
              ? 'Message vocal'
              : (last.content.trim().isEmpty
                    ? 'Nouveau message'
                    : last.content),
          timestamp: last.createdAt,
          isUnread: last.senderId != meId,
        ),
      );
    }
    out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return out;
  }

  Future<void> _openNotifications() async {
    final rows = await _loadNotifications();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NotificationsScreen(notifications: rows),
      ),
    );
    await _refreshNotificationCount();
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_rounded),
        if (_notificationCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _notificationCount > 99 ? '99+' : '$_notificationCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CommerceSettingsScreen()));
  }

  Future<void> _logout() async {
    await djangoAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthRouter()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;
    final revenue = summary != null
        ? '${summary.todayRevenue.toStringAsFixed(0)} CDF'
        : '—';
    final transactions = summary != null ? '${summary.transactions}' : '—';
    final ticket = summary != null
        ? '${summary.averageTicket.toStringAsFixed(0)} CDF'
        : '—';
    final actionItems = <_DashboardActionItem>[
      _DashboardActionItem(
        icon: Icons.space_dashboard_outlined,
        title: 'Dashboard',
        subtitle: 'Vue globale',
        tone: const Color(0xFFE8F2FF),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminOverviewScreen()),
          );
        },
      ),
      _DashboardActionItem(
        icon: Icons.warning_amber_rounded,
        title: _profile.key == 'salon_coiffure'
            ? 'Performance'
            : 'Stock critique',
        subtitle: _profile.key == 'salon_coiffure'
            ? (_topProduct == '—' ? 'Aucune prestation' : 'Top: $_topProduct')
            : (_criticalStock > 0 ? '$_criticalStock en alerte' : 'Stock sain'),
        tone: const Color(0xFFFFF4E8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _profile.key == 'salon_coiffure'
                  ? const SalonServiceScreen()
                  : const InventoryScreen(),
            ),
          );
        },
      ),
      _DashboardActionItem(
        icon: Icons.trending_up_rounded,
        title: _profile.topPerformerLabel,
        subtitle: _topProduct == '—' ? 'Aucune vente' : _topProduct,
        tone: const Color(0xFFEAF9EF),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _profile.key == 'salon_coiffure'
                  ? const SalonServiceScreen()
                  : const QuickSaleScreen(),
            ),
          );
        },
      ),
      _DashboardActionItem(
        icon: Icons.person_search_rounded,
        title: 'Clients',
        subtitle: '$_inactiveCustomers à relancer',
        tone: const Color(0xFFF2ECFF),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CustomersScreen()));
        },
      ),
      _DashboardActionItem(
        icon: Icons.store_mall_directory_outlined,
        title: 'Fournisseurs',
        subtitle: 'Trouver et commander',
        tone: const Color(0xFFEAF6FF),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupplierNetworkScreen()),
          );
        },
      ),
      _DashboardActionItem(
        icon: Icons.analytics_outlined,
        title: context.tr('Analyses'),
        subtitle: context.tr('Tendances'),
        tone: const Color(0xFFEFF8F5),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const InsightsScreen()));
        },
      ),
      _DashboardActionItem(
        icon: Icons.account_balance_outlined,
        title: context.tr('Comptabilite'),
        subtitle: context.tr('Rapports'),
        tone: const Color(0xFFF7F2EB),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AccountingScreen()));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${context.tr('Assistant')} ${_profile.label.toLowerCase()}',
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Actualiser'),
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('Parametres'),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: context.tr('Deconnexion'),
          ),
          IconButton(
            onPressed: _openNotifications,
            icon: _buildNotificationIcon(),
            tooltip: context.tr('Alertes'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KpiHeader(
            theme: theme,
            revenue: revenue,
            transactions: transactions,
            averageTicket: ticket,
            loading: _loading,
            profile: _profile,
          ),
          const SizedBox(height: 12),
          _CategoryBanner(profile: _profile),
          const SizedBox(height: 16),
          Text(context.tr('Aujourd\'hui'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _KpiGrid(
            summary: summary,
            profile: _profile,
            topProduct: _topProduct,
            criticalStock: _criticalStock,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Actions prioritaires'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _ActionSquareGrid(items: actionItems),
        ],
      ),
    );
  }
}

class _UiNotification {
  const _UiNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isUnread,
  });

  final String title;
  final String body;
  final String timestamp;
  final bool isUnread;
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen({required this.notifications});

  final List<_UiNotification> notifications;

  String _formatDayHour(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const days = <String>[
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final day = days[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day $d/$m • $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? const Center(
              child: Text('Aucune notification disponible pour le moment.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.notifications_none_rounded),
                        ),
                        if (n.isUnread)
                          const Positioned(
                            right: -1,
                            top: -1,
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDayHour(n.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _KpiHeader extends StatelessWidget {
  const _KpiHeader({
    required this.theme,
    required this.revenue,
    required this.transactions,
    required this.averageTicket,
    required this.loading,
    required this.profile,
  });

  final ThemeData theme;
  final String revenue;
  final String transactions;
  final String averageTicket;
  final bool loading;
  final BusinessCategoryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: profile.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.headerMetricLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  revenue,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                  ),
                ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniKpi(label: 'Transactions', value: transactions),
              const SizedBox(width: 18),
              _MiniKpi(label: 'Panier moyen', value: averageTicket),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.summary,
    required this.profile,
    required this.topProduct,
    required this.criticalStock,
  });

  final SalesSummaryModel? summary;
  final BusinessCategoryProfile profile;
  final String topProduct;
  final int criticalStock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSalon = profile.key == 'salon_coiffure';
    final transactionsValue = summary != null
        ? '${summary!.transactions}'
        : '—';
    final avgTicketValue = summary != null
        ? '${summary!.averageTicket.toStringAsFixed(0)} CDF'
        : '—';
    final topValue = topProduct == '—'
        ? (isSalon ? 'Aucune prestation' : 'Aucune vente')
        : topProduct;
    final stockValue = '$criticalStock';

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _KpiTile(
          label: 'Transactions',
          value: transactionsValue,
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : const Color(0xFFEAF2FF),
        ),
        _KpiTile(
          label: 'Panier moyen',
          value: avgTicketValue,
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : const Color(0xFFEAF2FF),
        ),
        _KpiTile(
          label: isSalon ? 'Top coiffeur' : profile.topPerformerLabel,
          value: topValue,
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : const Color(0xFFEAF2FF),
        ),
        _KpiTile(
          label: isSalon ? 'Paiements du jour' : 'Stock critique',
          value: isSalon ? transactionsValue : stockValue,
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : const Color(0xFFEAF2FF),
        ),
      ],
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.profile});

  final BusinessCategoryProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : profile.softColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: profile.accentColor.withValues(alpha: 0.16),
            child: Icon(profile.heroIcon, color: profile.accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${profile.label} - ${profile.subtitle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBED3FF)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF0B4FDC),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF083893),
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionItem {
  const _DashboardActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback onTap;
}

class _ActionSquareGrid extends StatelessWidget {
  const _ActionSquareGrid({required this.items});

  final List<_DashboardActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) => _ActionSquareTile(item: items[index]),
    );
  }
}

class _ActionSquareTile extends StatelessWidget {
  const _ActionSquareTile({required this.item});

  final _DashboardActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBED3FF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 22, color: const Color(0xFF0B4FDC)),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF083893),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0B4FDC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
