import 'package:flutter/material.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dummySubjects = [
      _SubjectGrade('Mathématiques', 'Classe: 5e', 14.5),
      _SubjectGrade('Français', 'Classe: 5e', 12.0),
      _SubjectGrade('Sciences', 'Classe: 5e', 16.0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes et bulletins'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Évolution des notes',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Une courbe simple d’évolution sera affichée ici (à implémenter avec les données de l’API).',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          ...dummySubjects.map(
            (s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.classInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (s.average / 20).clamp(0, 1),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Moyenne du trimestre: ${s.average.toStringAsFixed(1)}/20',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Ouvrir la liste des bulletins PDF téléchargés (offline).
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Voir les bulletins PDF'),
          ),
        ],
      ),
    );
  }
}

class _SubjectGrade {
  _SubjectGrade(this.name, this.classInfo, this.average);

  final String name;
  final String classInfo;
  final double average;
}

