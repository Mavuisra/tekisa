library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';
import '../../settings/presentation/commerce_settings_screen.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final _authLocal = AuthLocalDataSource();
  int _periodDays = 30;
  Map<String, dynamic>? _report;
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
      final report = await source.getAccountingReports(days: _periodDays);
      if (!mounted) return;
      setState(() {
        _report = report;
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
    final report = _report ?? const <String, dynamic>{};
    final kpis = Map<String, dynamic>.from(report['kpis'] as Map? ?? {});
    final income = Map<String, dynamic>.from(
      report['income_statement'] as Map? ?? {},
    );
    final balance = Map<String, dynamic>.from(
      report['balance_sheet'] as Map? ?? {},
    );
    final cashflow = Map<String, dynamic>.from(
      report['cashflow'] as Map? ?? {},
    );
    final trial = (report['trial_balance'] as List<dynamic>? ?? []);
    final journal = (report['journal'] as List<dynamic>? ?? []);

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    Widget money(dynamic v) => Text(
      '${toDouble(v).toStringAsFixed(0)} CDF',
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptabilité SYCOHADA'),
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
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text('Période', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [7, 30, 90].map((d) {
                  final selected = _periodDays == d;
                  return ChoiceChip(
                    label: Text('$d jours'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _periodDays = d);
                      _load();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Synthèse comptable', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'KPI clés',
                child: Column(
                  children: [
                    _LineValue(
                      label: 'Ventes brutes',
                      value: money(kpis['gross_sales']),
                    ),
                    _LineValue(
                      label: 'Remises',
                      value: money(kpis['discounts']),
                    ),
                    _LineValue(
                      label: 'Ventes nettes',
                      value: money(kpis['net_sales']),
                    ),
                    _LineValue(
                      label: 'Coût des ventes',
                      value: money(kpis['cogs']),
                    ),
                    _LineValue(
                      label: 'Résultat net',
                      value: money(kpis['net_result']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Compte de résultat', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Période sélectionnée',
                child: Column(
                  children: [
                    _LineValue(
                      label: 'Ventes nettes',
                      value: money(income['net_sales']),
                    ),
                    _LineValue(
                      label: 'Coût des ventes',
                      value: money(income['cost_of_goods_sold']),
                    ),
                    _LineValue(
                      label: 'Marge brute',
                      value: money(income['gross_profit']),
                    ),
                    _LineValue(
                      label: 'Charges opérationnelles',
                      value: money(income['operating_expenses']),
                    ),
                    _LineValue(
                      label: 'Résultat net',
                      value: money(income['net_result']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Bilan simplifié', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Actif / Passif',
                child: Column(
                  children: [
                    _LineValue(
                      label: 'Actif - Trésorerie',
                      value: money((balance['assets'] as Map?)?['cash']),
                    ),
                    _LineValue(
                      label: 'Actif - Stock',
                      value: money((balance['assets'] as Map?)?['inventory']),
                    ),
                    _LineValue(
                      label: 'Actif - Créances',
                      value: money((balance['assets'] as Map?)?['receivables']),
                    ),
                    _LineValue(
                      label: 'Passif - Dettes',
                      value: money(
                        (balance['liabilities'] as Map?)?['payables'],
                      ),
                    ),
                    _LineValue(
                      label: 'Capitaux propres',
                      value: money(
                        (balance['equity'] as Map?)?['retained_earnings'],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Flux de trésorerie', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Tableau simplifié',
                child: Column(
                  children: [
                    _LineValue(
                      label: 'Flux opérationnels entrants',
                      value: money(cashflow['operating_inflows']),
                    ),
                    _LineValue(
                      label: 'Flux opérationnels sortants',
                      value: money(cashflow['operating_outflows']),
                    ),
                    _LineValue(
                      label: 'Flux net opérationnel',
                      value: money(cashflow['net_operating_cashflow']),
                    ),
                    _LineValue(
                      label: 'Flux investissement',
                      value: money(cashflow['investing_cashflow']),
                    ),
                    _LineValue(
                      label: 'Flux financement',
                      value: money(cashflow['financing_cashflow']),
                    ),
                    _LineValue(
                      label: 'Flux net global',
                      value: money(cashflow['net_cashflow']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Balance générale (SYCOHADA)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Balance',
                child: Column(
                  children: trial.map((row) {
                    final map = Map<String, dynamic>.from(row as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 36, child: Text('${map['account']}')),
                          Expanded(child: Text('${map['label']}')),
                          Text(
                            'D ${toDouble(map['debit']).toStringAsFixed(0)}',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'C ${toDouble(map['credit']).toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text('Journal comptable', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...journal.map((j) {
                final entry = Map<String, dynamic>.from(j as Map);
                final lines = (entry['lines'] as List<dynamic>? ?? []);
                return _SectionCard(
                  title: '${entry['date']} • ${entry['piece']}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry['description']}'),
                      const SizedBox(height: 6),
                      ...lines.map((line) {
                        final l = Map<String, dynamic>.from(line as Map);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${l['account']} ${l['label']}  |  D ${toDouble(l['debit']).toStringAsFixed(0)}  C ${toDouble(l['credit']).toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Plan comptable SYCOHADA (classes 1 à 8)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const _ClassRow(code: 'Classe 1', label: 'Ressources durables'),
              const _ClassRow(code: 'Classe 2', label: 'Actif immobilisé'),
              const _ClassRow(code: 'Classe 3', label: 'Stocks'),
              const _ClassRow(code: 'Classe 4', label: 'Tiers'),
              const _ClassRow(code: 'Classe 5', label: 'Trésorerie'),
              const _ClassRow(code: 'Classe 6', label: 'Charges'),
              const _ClassRow(code: 'Classe 7', label: 'Produits'),
              const _ClassRow(
                code: 'Classe 8',
                label: 'Autres charges/produits',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LineValue extends StatelessWidget {
  const _LineValue({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          value,
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
