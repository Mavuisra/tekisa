library;

import 'package:flutter/material.dart';

import '../../../core/business/business_category_profile.dart';
import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/models/commerce_models.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';
import '../../settings/presentation/commerce_settings_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _authLocal = AuthLocalDataSource();
  BusinessCategoryProfile _profile = BusinessCategoryProfiles.boutique;
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<CustomerSummaryModel> _customers = [];

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
    final user = _authLocal.getUser();
    _profile = BusinessCategoryProfiles.fromKey(user?.businessCategory);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerSummaryModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
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
    setState(() {
      _loading = true;
      _error = null;
    });
    final source = await _source();
    if (source == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Session expirée.';
      });
      return;
    }
    try {
      final data = await source.getCustomersSummary();
      if (!mounted) return;
      setState(() {
        _customers = data;
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

  Future<void> _openCreateCustomerSheet() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String segment = 'regular';
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nouveau ${_profile.customerNounSingular}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: segment,
                      decoration: const InputDecoration(labelText: 'Segment'),
                      items: const [
                        DropdownMenuItem(
                          value: 'regular',
                          child: Text('Régulier'),
                        ),
                        DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                        DropdownMenuItem(
                          value: 'À relancer',
                          child: Text('À relancer'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (v) =>
                                setModalState(() => segment = v ?? 'regular'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Le nom du ${_profile.customerNounSingular} est requis.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final source = await _source();
                              if (source == null) return;
                              setModalState(() => saving = true);
                              try {
                                await source.createCustomer(
                                  fullName: name,
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  segment: segment,
                                  notes: notesCtrl.text.trim(),
                                );
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${_profile.customerNounSingular[0].toUpperCase()}${_profile.customerNounSingular.substring(1)} cree avec succes.',
                                    ),
                                  ),
                                );
                                await _load();
                              } catch (e) {
                                if (!context.mounted) return;
                                setModalState(() => saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Creer le ${_profile.customerNounSingular}'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveCount = _customers.where((c) {
      if (c.lastPurchaseAt == null) return true;
      final dt = DateTime.tryParse(c.lastPurchaseAt!);
      if (dt == null) return true;
      return DateTime.now().difference(dt).inDays >= 30;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile.customersTitle),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : _profile.softColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: theme.dividerColor)
                    : Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: _profile.accentColor.withValues(
                      alpha: 0.16,
                    ),
                    child: Icon(
                      _profile.heroIcon,
                      size: 17,
                      color: _profile.accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _profile.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un ${_profile.customerNounSingular}',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : _profile.softColor.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: theme.dividerColor)
                    : Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _profile.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$inactiveCount ${_profile.customerNounPlural} sans achat recent. Lancez une relance ciblee.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : _profile.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filtered.isEmpty)
              Text('Aucun ${_profile.customerNounSingular} trouve.')
            else
              ..._filtered.map(
                (c) => _CustomerCard(customer: c, profile: _profile),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomerSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Nouveau ${_profile.customerNounSingular}'),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.profile});

  final CustomerSummaryModel customer;
  final BusinessCategoryProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final segment = customer.segment;
    final tone = switch (segment) {
      'VIP' => isDark ? const Color(0xFF233A32) : const Color(0xFFEAFBF4),
      'À relancer' =>
        isDark ? const Color(0xFF3A3122) : const Color(0xFFFFF7E6),
      _ => isDark ? theme.colorScheme.surface : profile.softColor,
    };
    final last = customer.lastPurchaseAt != null
        ? DateTime.tryParse(customer.lastPurchaseAt!)
        : null;
    final lastLabel = last == null
        ? 'Aucun achat'
        : 'Il y a ${DateTime.now().difference(last).inDays} jour(s)';
    final lastActivityLabel = switch (profile.key) {
      'restaurant' => 'Derniere visite',
      'pharmacie' => 'Dernier achat',
      _ => 'Dernier achat',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.dividerColor)
            : Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tone,
          child: Text(
            customer.fullName.isNotEmpty
                ? customer.fullName.characters.first
                : '?',
          ),
        ),
        title: Text(customer.fullName, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '$lastActivityLabel: $lastLabel',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : null,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${customer.totalSpent.toStringAsFixed(0)} CDF',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              segment,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
