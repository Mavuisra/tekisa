library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/offline/sqlite_cache_service.dart';
import '../../../core/offline/tenant_context.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';

class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({super.key});

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  final _authLocal = AuthLocalDataSource();
  final _cache = SqliteCacheService();
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String? _error;
  double _salesAmount = 0;
  List<_CashExpense> _expenses = const [];

  double get _expensesAmount => _expenses.fold(0, (sum, e) => sum + e.amount);
  double get _balance => _salesAmount - _expensesAmount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateKey(DateTime value) => value.toIso8601String().substring(0, 10);

  String _expenseCacheKey(DateTime value) =>
      'commerce/cash/expenses?date=${_dateKey(value)}';

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

  Future<List<_CashExpense>> _readExpenses(DateTime date) async {
    final tenant = TenantContext.current();
    if (tenant == null) return const [];
    final data = await _cache.read(
      tenantId: tenant.tenantId,
      resourceKey: _expenseCacheKey(date),
    );
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => _CashExpense.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _saveExpenses(DateTime date, List<_CashExpense> expenses) async {
    final tenant = TenantContext.current();
    if (tenant == null) return;
    await _cache.save(
      tenantId: tenant.tenantId,
      resourceKey: _expenseCacheKey(date),
      payload: expenses.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final source = await _source();
    double salesAmount = 0;
    try {
      if (source != null) {
        final sales = await source.getSalesList(date: _dateKey(_selectedDate));
        salesAmount = sales
            .where(
              (s) =>
                  s.status.toLowerCase() != 'cancelled' &&
                  s.status.toLowerCase() != 'canceled',
            )
            .fold(0, (sum, sale) => sum + sale.total);
      }
      final expenses = await _readExpenses(_selectedDate);
      if (!mounted) return;
      setState(() {
        _salesAmount = salesAmount;
        _expenses = expenses;
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

  Future<void> _addExpense() async {
    final reasonCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? errorText;
    final expense = await showDialog<_CashExpense>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Nouvelle depense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Motif / justification',
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Montant (CDF)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (reason.isEmpty) {
                  setModalState(
                    () => errorText = 'La justification est obligatoire.',
                  );
                  return;
                }
                if (amount <= 0) {
                  setModalState(
                    () => errorText = 'Le montant doit etre superieur a 0.',
                  );
                  return;
                }
                Navigator.of(context).pop(
                  _CashExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    reason: reason,
                    amount: amount,
                    createdAt: DateTime.now().toIso8601String(),
                  ),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    reasonCtrl.dispose();
    amountCtrl.dispose();
    if (expense == null) return;
    final next = [expense, ..._expenses];
    await _saveExpenses(_selectedDate, next);
    if (!mounted) return;
    setState(() => _expenses = next);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Depense enregistree.')));
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
    final dateLabel = _dateKey(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Date',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text('Date: $dateLabel', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 10),
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
            _amountCard(
              title: 'Entrees de caisse (ventes)',
              amount: _salesAmount,
              color: const Color(0xFF065F46),
            ),
            _amountCard(
              title: 'Depenses justifiees',
              amount: _expensesAmount,
              color: const Color(0xFFB45309),
            ),
            _amountCard(
              title: 'Solde caisse',
              amount: _balance,
              color: _balance >= 0
                  ? const Color(0xFF035D8A)
                  : const Color(0xFFB91C1C),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _addExpense,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text('Enregistrer une depense'),
            ),
            const SizedBox(height: 14),
            Text('Journal des depenses', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_expenses.isEmpty)
              const Text('Aucune depense enregistree.')
            else
              ..._expenses.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.amount.toStringAsFixed(0)} CDF',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(e.reason),
                      const SizedBox(height: 4),
                      Text(
                        e.createdAt.replaceFirst('T', ' ').substring(0, 16),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Ajouter dépense'),
      ),
    );
  }

  Widget _amountCard({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            '${amount.toStringAsFixed(0)} CDF',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CashExpense {
  const _CashExpense({
    required this.id,
    required this.reason,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String reason;
  final double amount;
  final String createdAt;

  factory _CashExpense.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    return _CashExpense(
      id: (json['id'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
      amount: amountValue is num
          ? amountValue.toDouble()
          : double.tryParse('$amountValue') ?? 0,
      createdAt: (json['created_at'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'amount': amount,
      'created_at': createdAt,
    };
  }
}
