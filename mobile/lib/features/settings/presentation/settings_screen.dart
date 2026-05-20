import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil du parent'),
            subtitle: const Text('Nom, numéro de téléphone, langue'),
            onTap: () {
              // TODO: Écran de profil parent.
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir les alertes importantes'),
            value: true,
            onChanged: (value) {
              // TODO: Sauver la préférence localement (Hive) et côté serveur.
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined),
            title: const Text('SMS importants'),
            subtitle: const Text('Absences, paiements, résultats'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.offline_pin_outlined),
            title: const Text('Mode hors-ligne'),
            subtitle: const Text('Les données récentes sont disponibles sans internet'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () {
              // TODO: Effacer les tokens (SecureStorage) et revenir à l’écran de login.
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'CisnetKids • v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

