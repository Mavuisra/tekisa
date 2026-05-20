import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connecté', style: Theme.of(context).textTheme.titleSmall),
                    Text(auth.user!['email']?.toString() ?? auth.user!['phone']?.toString() ?? 'Parent'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Mes enfants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          childrenAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun enfant lié pour le moment.')));
              }
              return Column(
                children: list.map((e) {
                  final name = e['full_name'] as String? ?? 'Enfant';
                  final id = e['id'] as String? ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/child/$id'),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Erreur: $e'))),
          ),
        ],
      ),
    );
  }
}
