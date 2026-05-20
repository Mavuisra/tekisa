library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';
import '../../../presentation/widgets/glass_card.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  final _authLocal = AuthLocalDataSource();
  List<Map<String, dynamic>> _classes = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      final data = await ds.getMyClasses();
      if (!mounted) return;
      setState(() {
        _classes = data;
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

  Future<void> _openClass(Map<String, dynamic> cls) async {
    final ds = await _ds();
    if (ds == null) return;
    if (!mounted) return;
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ds.getClassStudents((cls['id'] as num).toInt()),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snap.data!;
            final classroom = Map<String, dynamic>.from(
              (data['classroom'] as Map?) ?? const {},
            );
            final students = (data['students'] as List?) ?? const [];
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${classroom['name'] ?? ''}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Élèves (${students.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = Map<String, dynamic>.from(students[i] as Map);
                        final name =
                            '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                                .trim();
                        return ListTile(
                          leading: CircleAvatar(
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
                          title: Text(name),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mes classes', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mes classes', style: theme.textTheme.titleMedium),
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

    final totalClasses = _classes.length;
    final totalStudents = _classes.fold<int>(
      0,
      (sum, c) => sum + ((c['student_count'] as int?) ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Mes classes', style: theme.textTheme.titleMedium),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stat cards horizontales en haut
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                          _ClassesStatCard(
                            label: 'Classes',
                            value: '$totalClasses',
                            icon: Icons.class_outlined,
                            color: const Color(0xFF3DBEA9),
                          ),
                          _ClassesStatCard(
                            label: 'Élèves',
                            value: '$totalStudents',
                            icon: Icons.people_alt_outlined,
                            color: const Color(0xFF4C6FFF),
                          ),
                        ]
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: w,
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Liste des classes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_classes.isEmpty)
              GlassCard(
                child: Text(
                  'Aucune classe assignée.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ..._classes.map((cls) {
                final c = Map<String, dynamic>.from(cls);
                final name = '${c['name'] ?? ''}';
                final level = '${c['level'] ?? ''}';
                final school = '${c['school_name'] ?? ''}';
                final studentCount = (c['student_count'] as int?) ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(3),
                      onTap: () => _openClass(c),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3DBEA9).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.class_outlined,
                              color: Color(0xFF3DBEA9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: theme.textTheme.titleMedium),
                                Text(
                                  [
                                    level,
                                    school,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF84878A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$studentCount élèves',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF84878A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
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

class _ClassesStatCard extends StatelessWidget {
  const _ClassesStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF84878A),
            ),
          ),
        ],
      ),
    );
  }
}
