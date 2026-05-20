library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';
import '../../../presentation/widgets/glass_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _authLocal = AuthLocalDataSource();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  bool _posting = false;

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
      final ds = await _ds();
      if (ds == null) {
        setState(() {
          _error = 'Session expirée. Reconnectez-vous.';
          _loading = false;
        });
        return;
      }
      final data = await ds.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Accueil', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Accueil', style: theme.textTheme.titleMedium),
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

    final teacher = (_data?['teacher'] as Map?) ?? const {};
    final classes = (_data?['classes'] as List?) ?? const [];

    final totalClasses = classes.length;
    final totalStudents = classes.fold<int>(
      0,
      (sum, c) => sum + ((c as Map)['student_count'] as int? ?? 0),
    );
    final totalPresentToday = classes.fold<int>(
      0,
      (sum, c) => sum + ((c as Map)['present_today'] as int? ?? 0),
    );
    final totalAssessmentsThisMonth = classes.fold<int>(
      0,
      (sum, c) => sum + ((c as Map)['assessments_this_month'] as int? ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Espace enseignant', style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            tooltip: 'Nouvelle annonce / devoir',
            onPressed: () => _openCreatePostSheet(classes),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header enseignant
            GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF3DBEA9,
                        ).withOpacity(0.12),
                        child: Text(
                          ((teacher['full_name'] as String?) ?? 'E')[0]
                              .toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
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
                              (teacher['full_name'] as String?) ?? 'Enseignant',
                              style: theme.textTheme.titleLarge,
                            ),
                            if ((teacher['title'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 2),
                              Text(
                                teacher['title'] as String,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Vue d’ensemble de vos classes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF84878A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1),
            const SizedBox(height: 16),
            // Stat cards horizontales
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                          _StatCard(
                            label: 'Classes',
                            value: '$totalClasses',
                            icon: Icons.class_outlined,
                            color: const Color(0xFF3DBEA9),
                          ),
                          _StatCard(
                            label: 'Élèves',
                            value: '$totalStudents',
                            icon: Icons.people_alt_outlined,
                            color: const Color(0xFF4C6FFF),
                          ),
                          _StatCard(
                            label: 'Présents',
                            value: '$totalPresentToday',
                            icon: Icons.check_circle_outline,
                            color: Colors.green.shade600,
                          ),
                          _StatCard(
                            label: 'Éval. (mois)',
                            value: '$totalAssessmentsThisMonth',
                            icon: Icons.assignment_outlined,
                            color: const Color(0xFFFFB020),
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
            const SizedBox(height: 20),
            Text('Mes classes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (classes.isEmpty)
              GlassCard(
                child: Text(
                  'Aucune classe assignée.',
                  style: theme.textTheme.bodySmall,
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1)
            else ...[
              // Bandeau horizontal de classes (chips)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final m = Map<String, dynamic>.from(classes[index] as Map);
                    final name = '${m['name'] ?? ''}';
                    final level = '${m['level'] ?? ''}';
                    return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
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
                                Icons.class_outlined,
                                size: 18,
                                color: Color(0xFF3DBEA9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (level.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '· $level',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 250.ms, delay: (index * 40).ms)
                        .slideX(begin: 0.1);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Liste verticale détaillée des classes
              ...classes.asMap().entries.map((entry) {
                final index = entry.key;
                final m = Map<String, dynamic>.from(entry.value as Map);
                final name = '${m['name'] ?? ''}';
                final level = '${m['level'] ?? ''}';
                final school = '${m['school_name'] ?? ''}';
                final studentCount = (m['student_count'] as int?) ?? 0;
                final present = (m['present_today'] as int?) ?? 0;
                final absent = (m['absent_today'] as int?) ?? 0;
                final assessmentsCount =
                    (m['assessments_this_month'] as int?) ?? 0;
                final totalToday = (present + absent).clamp(0, studentCount);
                final ratio = studentCount == 0
                    ? 0.0
                    : (present / studentCount).clamp(0, 1).toDouble();

                final card = GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Présence du jour',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE3E7EC),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF3DBEA9),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$present / $studentCount présents'
                                  '${totalToday > 0 ? ' · ${((present / (totalToday == 0 ? 1 : totalToday)) * 100).toStringAsFixed(0)}%' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _chip('Élèves', '$studentCount', theme),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _chip('Absents', '$absent', theme)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _chip(
                              'Éval. mois',
                              '$assessmentsCount',
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: (index * 70).ms,
                        curve: Curves.easeOut,
                      )
                      .slideY(begin: 0.12),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3FF),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF1877F2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openCreatePostSheet(List classes) async {
    final theme = Theme.of(context);
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune classe disponible pour publier.')),
      );
      return;
    }

    String type = 'assignment';
    int selectedClassId = (classes.first as Map)['id'] as int;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? dueDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nouvelle publication',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez un devoir, un exercice ou une annonce pour informer les parents.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF84878A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Type', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Devoir'),
                          selected: type == 'assignment',
                          onSelected: (v) => setModalState(() {
                            type = 'assignment';
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Exercice'),
                          selected: type == 'exercise',
                          onSelected: (v) => setModalState(() {
                            type = 'exercise';
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Annonce'),
                          selected: type == 'announcement',
                          onSelected: (v) => setModalState(() {
                            type = 'announcement';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Classe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: (c as Map)['id'] as int,
                              child: Text('${c['name'] ?? ''}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() {
                          selectedClassId = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        hintText: 'ex: Devoir de mathématiques chapitre 3',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Détails',
                        hintText:
                            'Instructions pour les élèves et informations pour les parents…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (type != 'announcement')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now.subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    dueDate =
                                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              label: Text(
                                dueDate == null
                                    ? 'Ajouter une date limite'
                                    : 'Date limite: $dueDate',
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _posting
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final body = bodyController.text.trim();
                                if (title.isEmpty || body.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Remplissez au moins le titre et les détails.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _posting = true;
                                });
                                try {
                                  final ds = await _ds();
                                  if (ds == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Session expirée. Reconnectez-vous.',
                                        ),
                                      ),
                                    );
                                  } else {
                                    await ds.createPost(
                                      type: type,
                                      classroomId: selectedClassId,
                                      title: title,
                                      body: body,
                                      dueDate: dueDate,
                                    );
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Publication envoyée aux parents de la classe sélectionnée.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            RegExp(r'^Exception: '),
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _posting = false;
                                    });
                                  }
                                }
                              },
                        icon: _posting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _posting
                              ? 'Envoi…'
                              : 'Publier et notifier les parents',
                        ),
                      ),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
