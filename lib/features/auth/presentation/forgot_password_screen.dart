library;

import 'package:flutter/material.dart';

import '../../../core/support/support_contact.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final opened = await openWhatsAppSupport(
      message:
          'Bonjour, je n\'arrive pas a recuperer mon mot de passe sur TEKISA.',
    );
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d\'ouvrir WhatsApp sur cet appareil.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'aide pour récupérer votre compte ?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cliquez sur le bouton ci-dessous pour contacter le support '
                    'via WhatsApp.',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Numéro: 0821633587',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _contactSupport(context),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Contacter via WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
