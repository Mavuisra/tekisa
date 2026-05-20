import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dummyDays = [
      _DayAttendance('Lun 01', 'Présent', Colors.green),
      _DayAttendance('Mar 02', 'Présent', Colors.green),
      _DayAttendance('Mer 03', 'En retard', Colors.orange),
      _DayAttendance('Jeu 04', 'Absent', Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Présences et retards'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Résumé du mois',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              _ChipStat(label: 'Présent', value: '18 j'),
              _ChipStat(label: 'Absent', value: '2 j'),
              _ChipStat(label: 'Retard', value: '3 j'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Détail par jour',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...dummyDays.map(
            (d) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: d.color.withOpacity(0.1),
                  child: Icon(
                    Icons.event_available_outlined,
                    color: d.color,
                  ),
                ),
                title: Text(d.label),
                subtitle: Text(d.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.06),
    );
  }
}

class _DayAttendance {
  _DayAttendance(this.label, this.status, this.color);

  final String label;
  final String status;
  final Color color;
}

