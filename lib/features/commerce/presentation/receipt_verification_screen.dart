library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/models/commerce_models.dart';

class ReceiptVerificationScreen extends StatefulWidget {
  const ReceiptVerificationScreen({super.key});

  @override
  State<ReceiptVerificationScreen> createState() =>
      _ReceiptVerificationScreenState();
}

class _ReceiptVerificationScreenState extends State<ReceiptVerificationScreen> {
  final _authLocal = AuthLocalDataSource();
  final _inputController = TextEditingController();
  ReceiptVerificationModel? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
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

  Future<void> _verify() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Saisissez la reference ou le contenu QR.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final source = await _source();
    if (source == null) {
      setState(() {
        _loading = false;
        _error = 'Session expiree.';
      });
      return;
    }
    try {
      final isPayload = raw.contains('REF:') || raw.contains(';');
      final result = await source.verifyReceipt(
        reference: isPayload ? null : raw,
        payload: isPayload ? raw : null,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
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

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final receipt = result?.receipt;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification de recu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _inputController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reference ou contenu QR',
              hintText: 'ex: REC-20260303-000123 ou REF:REC-...',
              prefixIcon: Icon(Icons.qr_code_2_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _verify,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(_loading ? 'Verification...' : 'Verifier'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _inputController.clear();
                    _result = null;
                    _error = null;
                  });
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
          ],
          if (result != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: result.valid
                    ? const Color(0xFFEAFBF4)
                    : const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: result.valid
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.valid ? 'Recu valide' : 'Recu non valide',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(result.detail),
                  if (receipt != null) ...[
                    const SizedBox(height: 8),
                    Text('Reference: ${result.reference ?? '-'}'),
                    Text('Date: ${_fmtDate(receipt.createdAt)}'),
                    Text(
                      'Client: ${result.customerName?.isNotEmpty == true ? result.customerName : 'Client libre'}',
                    ),
                    Text('Paiement: ${receipt.paymentMethod}'),
                    Text('Total: ${receipt.total.toStringAsFixed(0)} CDF'),
                    const SizedBox(height: 8),
                    const Divider(),
                    ...receipt.items
                        .take(8)
                        .map(
                          (it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${it.productName} x${it.quantity}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text('${it.lineTotal.toStringAsFixed(0)} CDF'),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
