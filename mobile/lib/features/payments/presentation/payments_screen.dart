import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final invoices = [
      _Invoice('Frais scolaires trimestre 1', '120 000 CDF', 'En attente'),
      _Invoice('Uniforme', '40 000 CDF', 'Payé'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Solde et factures',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez suivre ici les factures et simuler un paiement Mobile Money.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          ...invoices.map(
            (i) => Card(
              child: ListTile(
                title: Text(i.title),
                subtitle: Text(i.amount),
                trailing: _StatusPill(status: i.status),
                onTap: () {
                  // TODO: Ouvrir le détail de la facture et initier un paiement Mobile Money.
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Invoice {
  _Invoice(this.title, this.amount, this.status);

  final String title;
  final String amount;
  final String status;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Payé':
        color = Colors.green;
        break;
      case 'En attente':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
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

