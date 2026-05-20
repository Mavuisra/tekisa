library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/models/commerce_models.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';
import '../../settings/presentation/commerce_settings_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _authLocal = AuthLocalDataSource();
  CommerceInsightsModel? _insights;
  bool _loading = true;
  String? _error;

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await _authLocal.getAccessToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Session expirée.';
      });
      return;
    }
    final client = DioClient(
      baseUrl: EnvConfig.apiBaseUrl,
      accessToken: token,
      getRefreshToken: () => _authLocal.getRefreshToken(),
      saveAccessToken: (t) => _authLocal.setAccessToken(t),
    );
    try {
      final data = await CommerceRemoteDataSource(client).getInsights();
      if (!mounted) return;
      setState(() {
        _insights = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _insights;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyses & rentabilité'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Parametres',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Deconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 10),
            ],
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Text(
                'Performance hebdomadaire',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _MiniChartCard(points: insights?.weeklyRevenue ?? const []),
              const SizedBox(height: 16),
              Text(
                'Produits les plus vendus',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if ((insights?.topProducts ?? const []).isEmpty)
                const Text('Aucune donnée de vente.')
              else
                ...insights!.topProducts.map(
                  (p) =>
                      _InsightRow(name: p.name, qty: p.qty, revenue: p.revenue),
                ),
              const SizedBox(height: 16),
              Text('Décisions suggérées', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              ...insights!.decisions.map(
                (d) => _DecisionCard(title: d.title, subtitle: d.subtitle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard({required this.points});

  final List<WeeklyRevenuePointModel> points;

  @override
  Widget build(BuildContext context) {
    final bars = points.map((e) => e.revenue).toList();
    final max = bars.isEmpty ? 1.0 : bars.reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: bars.map((value) {
          final normalized = max <= 0 ? 0.0 : (value / max).clamp(0, 1);
          return Container(
            width: 18,
            height: (normalized * 90) + 16,
            decoration: BoxDecoration(
              color: const Color(0xFF035D8A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.name,
    required this.qty,
    required this.revenue,
  });

  final String name;
  final int qty;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
          Text('$qty ventes', style: theme.textTheme.bodySmall),
          const SizedBox(width: 10),
          Text(
            '${revenue.toStringAsFixed(0)} CDF',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF047857),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
