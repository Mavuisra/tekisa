library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final _authLocal = AuthLocalDataSource();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  List<Map<String, dynamic>> _classes = const [];
  int? _selectedClassId;
  String? _selectedClassName;

  // Map studentId -> status
  Map<int, String> _statusByStudent = {};
  List<Map<String, dynamic>> _students = const [];

  String? _error;
  bool _loading = true;
  bool _saving = false;
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateFormat.format(DateTime.now());
    _init();
  }

  Future<TeacherRemoteDataSource?> _ds() async {
    final token = await _authLocal.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final client = DioClient(
      baseUrl: EnvConfig.apiBaseUrl,
      accessToken: token,
      getRefreshToken: () => _authLocal.getRefreshToken(),
      saveAccessToken: (t) => _authLocal.setAccessToken(t),
    );
    return TeacherRemoteDataSource(client);
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = await _ds();
      if (ds == null) {
        setState(() {
          _error = 'Session expirée. Reconnectez-vous.';
          _loading = false;
        });
        return;
      }
      final classes = await ds.getMyClasses();
      if (!mounted) return;
      if (classes.isEmpty) {
        setState(() {
          _classes = const [];
          _selectedClassId = null;
          _selectedClassName = null;
          _students = const [];
          _statusByStudent = {};
          _loading = false;
        });
        return;
      }
      final first = classes.first;
      _classes = classes;
      _selectedClassId = (first['id'] as num).toInt();
      _selectedClassName = '${first['name'] ?? ''}';
      await _loadForCurrentSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _loading = false;
      });
    }
  }

  Future<void> _loadForCurrentSelection() async {
    if (_selectedClassId == null) {
      setState(() {
        _students = const [];
        _statusByStudent = {};
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = await _ds();
      if (ds == null) {
        setState(() {
          _error = 'Session expirée. Reconnectez-vous.';
          _loading = false;
        });
        return;
      }
      final classId = _selectedClassId!;
      // Élèves de la classe
      final classData = await ds.getClassStudents(classId);
      final students = (classData['students'] as List?) ?? const [];

      // Présences existantes pour la classe et le mois courant
      final month = _selectedDate.substring(0, 7); // YYYY-MM
      final records = await ds.getMyAttendance(
        month: month,
        classroomId: classId,
      );

      // On ne garde que les enregistrements du jour sélectionné
      final mapForDay = <int, String>{};
      for (final r in records) {
        final date = (r['date'] as String?) ?? '';
        if (date.startsWith(_selectedDate)) {
          final sid = (r['student_id'] as num).toInt();
          mapForDay[sid] = (r['status'] as String?) ?? 'present';
        }
      }

      if (!mounted) return;
      setState(() {
        _students = students
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _statusByStudent = mapForDay;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateFormat.parse(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = _dateFormat.format(picked);
    });
    await _loadForCurrentSelection();
  }

  Future<void> _save() async {
    if (_selectedClassId == null || _students.isEmpty) return;
    setState(() {
      _saving = true;
    });
    try {
      final ds = await _ds();
      if (ds == null) {
        setState(() {
          _saving = false;
        });
        return;
      }
      final records = _students.map((s) {
        final sid = (s['id'] as num).toInt();
        final status = _statusByStudent[sid] ?? 'present';
        return {'student_id': sid, 'status': status, 'reason': ''};
      }).toList();

      await ds.saveAttendance(
        classroomId: _selectedClassId!,
        date: _selectedDate,
        records: records,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Présence enregistrée.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^Exception: '), '')),
        ),
      );
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return theme.colorScheme.error;
      case 'late':
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Présences', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Présences', style: theme.textTheme.titleMedium),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _init, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Présences', style: theme.textTheme.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Classe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    items: _classes
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: (c['id'] as num).toInt(),
                            child: Text('${c['name'] ?? ''}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final cls = _classes.firstWhere(
                        (c) => (c['id'] as num).toInt() == value,
                        orElse: () => _classes.first,
                      );
                      setState(() {
                        _selectedClassId = value;
                        _selectedClassName = '${cls['name'] ?? ''}';
                      });
                      _loadForCurrentSelection();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF84878A),
                        ),
                        const SizedBox(width: 6),
                        Text(_selectedDate, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadForCurrentSelection,
              child: _students.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Aucun élève trouvé pour cette classe.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        final id = (s['id'] as num).toInt();
                        final name =
                            '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                                .trim();
                        final status = _statusByStudent[id] ?? 'present';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(
                                  0xFF3DBEA9,
                                ).withOpacity(0.12),
                                child: Text(
                                  name.isNotEmpty
                                      ? name.characters.first.toUpperCase()
                                      : '?',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF3DBEA9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    if (_selectedClassName?.isNotEmpty ?? false)
                                      Text(
                                        _selectedClassName!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF84878A),
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ToggleButtons(
                                isSelected: [
                                  status == 'present',
                                  status == 'late',
                                  status == 'absent',
                                ],
                                borderRadius: BorderRadius.circular(3),
                                selectedColor: Colors.white,
                                fillColor: _statusColor(status, theme),
                                color: const Color(0xFF84878A),
                                constraints: const BoxConstraints(
                                  minHeight: 32,
                                  minWidth: 40,
                                ),
                                onPressed: (idx) {
                                  String newStatus = 'present';
                                  if (idx == 1) newStatus = 'late';
                                  if (idx == 2) newStatus = 'absent';
                                  setState(() {
                                    _statusByStudent[id] = newStatus;
                                  });
                                },
                                children: const [
                                  Text('P'),
                                  Text('R'),
                                  Text('A'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving ? 'Enregistrement…' : 'Enregistrer la présence',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
