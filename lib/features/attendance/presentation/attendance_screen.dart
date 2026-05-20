library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/env_config.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/parent_data_remote_datasource.dart';
import '../../../data/models/attendance_model.dart';
import '../../../core/network/dio_client.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  List<AttendanceRecordModel> _records = [];
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
      final list = await ds.getMyAttendance();
      if (mounted) {
        setState(() {
          _records = list;
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

  static Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Présent';
      case 'late':
        return 'En retard';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Présences et retards')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: List.generate(
                5,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  height: 64,
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
        appBar: AppBar(title: const Text('Présences et retards')),
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

    final presentCount = _records.where((r) => r.status == 'present').length;
    final absentCount = _records.where((r) => r.status == 'absent').length;
    final lateCount = _records.where((r) => r.status == 'late').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Présences et retards')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Résumé', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipStat(label: 'Présent', value: '$presentCount j'),
                _ChipStat(label: 'Absent', value: '$absentCount j'),
                _ChipStat(label: 'Retard', value: '$lateCount j'),
              ],
            ),
            const SizedBox(height: 16),
            Text('Détail par jour', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_records.isEmpty)
              Text(
                'Aucune présence enregistrée pour le moment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              )
            else
              ..._records.take(100).map((r) {
                final color = _statusColor(r.status);
                final dateStr = r.date.length >= 10
                    ? r.date.substring(0, 10)
                    : r.date;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(Icons.event_available_outlined, color: color),
                    ),
                    title: Text('$dateStr · ${r.studentName}'),
                    subtitle: Text(
                      _statusLabel(r.status) +
                          (r.classroomName.isNotEmpty
                              ? ' · ${r.classroomName}'
                              : ''),
                    ),
                  ),
                );
              }),
          ],
        ),
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
