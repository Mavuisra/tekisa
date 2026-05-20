library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/env_config.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/parent_data_remote_datasource.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/network/dio_client.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  List<InvoiceModel> _invoices = [];
  String? _error;
  bool _loading = true;

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
    try {
      final token = await _authLocal.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Session expirée.';
          _loading = false;
        });
        return;
      }
      final client = DioClient(
        baseUrl: EnvConfig.apiBaseUrl,
        accessToken: token,
        getRefreshToken: () => _authLocal.getRefreshToken(),
        saveAccessToken: (t) => _authLocal.setAccessToken(t),
      );
      final ds = ParentDataRemoteDataSource(client);
      final list = await ds.getMyInvoices();
      if (mounted) {
        setState(() {
          _invoices = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiements')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiements')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Solde et factures', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Suivez vos factures et payez via Mobile Money (M-Pesa, Airtel Money).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            if (_invoices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucune facture pour le moment.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              )
            else
              ..._invoices.map((i) {
                final statusLabel = i.status == 'paid'
                    ? 'Payé'
                    : i.status == 'partially_paid'
                    ? 'Partiel'
                    : i.status == 'cancelled'
                    ? 'Annulé'
                    : 'En attente';
                return Card(
                  child: ListTile(
                    title: Text(
                      i.description.isNotEmpty
                          ? i.description
                          : 'Facture · ${i.studentName}',
                    ),
                    subtitle: Text(
                      '${i.amount.toStringAsFixed(0)} ${i.currency} · ${i.dueDate}',
                    ),
                    trailing: _StatusPill(status: statusLabel),
                    onTap: () {},
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'Payé') color = Colors.green;
    if (status == 'En attente' || status == 'Partiel') color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
