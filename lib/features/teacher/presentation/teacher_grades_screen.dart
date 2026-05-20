library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';

class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen({super.key});

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();

  List<Map<String, dynamic>> _grades = const [];
  Map<int, _AssessmentInfo> _assessments = {};
  int? _selectedAssessmentId;
  final Map<int, TextEditingController> _controllers = {};

  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _load() async {
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
      final data = await ds.getMyGrades();
      if (!mounted) return;

      final grades = data.map((e) => Map<String, dynamic>.from(e)).toList();
      final assessments = <int, _AssessmentInfo>{};
      for (final g in grades) {
        final aidDynamic = g['assessment_id'];
        if (aidDynamic == null) continue;
        final aid = (aidDynamic as num).toInt();
        final label =
            '${g['subject_name'] ?? ''} • ${g['title'] ?? ''} • ${g['classroom_name'] ?? ''}'
                .trim();
        final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
        final date = (g['date'] as String?) ?? '';
        assessments[aid] = _AssessmentInfo(
          id: aid,
          label: label.isNotEmpty ? label : 'Évaluation $aid',
          maxScore: maxScore,
          date: date,
        );
      }

      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      for (final g in grades) {
        final sidDynamic = g['student_id'];
        if (sidDynamic == null) continue;
        final sid = (sidDynamic as num).toInt();
        final controller = TextEditingController(text: '${g['score'] ?? ''}');
        _controllers[sid] = controller;
      }

      setState(() {
        _grades = grades;
        _assessments = assessments;
        _selectedAssessmentId = assessments.keys.isNotEmpty
            ? assessments.keys.first
            : null;
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

  List<Map<String, dynamic>> get _filteredGrades {
    if (_selectedAssessmentId == null) return const [];
    return _grades
        .where(
          (g) => (g['assessment_id'] as num?)?.toInt() == _selectedAssessmentId,
        )
        .toList();
  }

  Future<void> _save() async {
    final aid = _selectedAssessmentId;
    if (aid == null) return;
    final records = <Map<String, dynamic>>[];
    for (final g in _filteredGrades) {
      final sid = (g['student_id'] as num?)?.toInt();
      if (sid == null) continue;
      final controller = _controllers[sid];
      if (controller == null) continue;
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final parsed = double.tryParse(text.replaceAll(',', '.'));
      if (parsed == null) continue;
      records.add({
        'student_id': sid,
        'score': parsed,
        'remarks': g['remarks'] ?? '',
      });
    }
    if (records.isEmpty) return;

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
      await ds.saveGrades(assessmentId: aid, records: records);
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes enregistrées.')));
      await _load();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notes', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notes', style: theme.textTheme.titleMedium),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    final assessmentsList = _assessments.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text('Notes', style: theme.textTheme.titleMedium)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedAssessmentId,
                    decoration: const InputDecoration(
                      labelText: 'Évaluation',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    items: assessmentsList
                        .map(
                          (a) => DropdownMenuItem<int>(
                            value: a.id,
                            child: Text(
                              a.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAssessmentId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _selectedAssessmentId == null || _filteredGrades.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Aucune note trouvée pour cette évaluation.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredGrades.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final g = _filteredGrades[index];
                        final student = '${g['student_name'] ?? ''}'.trim();
                        final classroom = '${g['classroom_name'] ?? ''}'.trim();
                        final controller =
                            _controllers[(g['student_id'] as num).toInt()]!;
                        final maxScore =
                            (g['max_score'] as num?)?.toDouble() ?? 20.0;
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
                                  student.isNotEmpty
                                      ? student.characters.first.toUpperCase()
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
                                      student,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      classroom,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF84878A),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: controller,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Note',
                                    suffixText:
                                        '/${maxScore.toStringAsFixed(0)}',
                                  ),
                                ),
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
                  _saving ? 'Enregistrement…' : 'Enregistrer les notes',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentInfo {
  const _AssessmentInfo({
    required this.id,
    required this.label,
    required this.maxScore,
    required this.date,
  });

  final int id;
  final String label;
  final double maxScore;
  final String date;
}
