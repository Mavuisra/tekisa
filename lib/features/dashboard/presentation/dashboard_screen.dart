library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/env_config.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/dashboard_remote_datasource.dart';
import '../../../data/datasources/parent_data_remote_datasource.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/learning_suggestion_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/network/dio_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  DashboardModel? _data;
  List<LearningSuggestionsResponse>? _suggestions;
  List<NotificationModel>? _notifications;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authLocal.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Session expirée. Reconnectez-vous.';
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
      final dataSource = DashboardRemoteDataSource(client);
      final data = await dataSource.getDashboard();
      final parentDataSource = ParentDataRemoteDataSource(client);
      List<LearningSuggestionsResponse>? suggestions;
      List<NotificationModel>? notifications;
      try {
        suggestions = await parentDataSource.getLearningSuggestions();
      } catch (_) {
        suggestions = [];
      }
      try {
        notifications = await parentDataSource.getMyNotifications();
      } catch (_) {
        notifications = [];
      }
      if (mounted) {
        setState(() {
          _data = data;
          _suggestions = suggestions;
          _notifications = notifications;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Accueil', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Accueil', style: theme.textTheme.titleMedium),
        ),
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
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final parentName = _data?.parent?.fullName ?? 'Parent';
    final children = _data?.children ?? [];
    final totalAttendance = children.fold<int>(
      0,
      (s, c) => s + c.attendanceDaysThisMonth,
    );
    final averages = children
        .where((c) => c.average != null)
        .map((c) => c.average!)
        .toList();
    final avgGrade = averages.isEmpty
        ? null
        : averages.reduce((a, b) => a + b) / averages.length;
    final totalPending = children.fold<double>(
      0,
      (s, c) => s + c.pendingAmount,
    );
    final totalUnpaid = children.fold<int>(
      0,
      (s, c) => s + c.unpaidInvoicesCount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(elevation: 0, backgroundColor: const Color(0xFFF5F7FA)),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header avec avatar + message
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF3DBEA9).withOpacity(0.15),
                  child: Text(
                    parentName.isNotEmpty
                        ? parentName.characters.first.toUpperCase()
                        : 'P',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF3DBEA9),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $parentName',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Suivi de vos enfants',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF84878A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rechercher un enfant, une classe…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF84878A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Catégories horizontales (purement visuel)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final bool isFirst = index == 0;
                  return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFF3DBEA9).withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 18,
                              color: const Color(0xFF3DBEA9),
                            ),
                            const SizedBox(width: 6),
                            Text(cat.label, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 250.ms, delay: (index * 40).ms)
                      .slideX(begin: 0.1);
                },
              ),
            ),
            const SizedBox(height: 20),
            // Annonces & devoirs (publications des enseignants pour la classe de l'enfant)
            if (_notifications != null) ...[
              ..._notifications!
                  .where((n) => n.type == 'teacher_post')
                  .map((n) => _buildAnnouncementCard(theme, n)),
              if (_notifications!.any((n) => n.type == 'teacher_post'))
                const SizedBox(height: 16),
            ],
            if (children.isEmpty) ...[
              Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Résumé', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun enfant rattaché à votre compte. Les informations apparaîtront ici une fois vos enfants enregistrés par l\'école.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1),
            ] else ...[
              // Liste verticale de cartes "cours" (un enfant = un cours)
              ...children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final ratio = (child.attendanceDaysThisMonth / 30)
                    .clamp(0, 1)
                    .toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3DBEA9), Color(0xFF54D3C0)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            child.displayName.characters.first.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.displayName,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            if (child.schoolName.isNotEmpty ||
                                child.classroomName.isNotEmpty)
                              Text(
                                [
                                  child.classroomName,
                                  child.schoolName,
                                ].where((s) => s.isNotEmpty).join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                            const SizedBox(height: 8),
                            // Barre de progression basée sur la présence ce mois
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
                              'Présence ce mois: ${child.attendanceDaysThisMonth} j · Moyenne: '
                              '${child.average != null ? child.average!.toStringAsFixed(1) : '—'}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              child.unpaidInvoicesCount > 0
                                  ? '${child.unpaidInvoicesCount} facture(s) en attente · '
                                        '${child.pendingAmount.toStringAsFixed(0)} CDF'
                                  : 'Paiements à jour',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: (index * 70).ms).slideY(begin: 0.12);
              }),
              const SizedBox(height: 16),
              // Suggestions de cours en ligne (selon notes par matière)
              if (_suggestions != null &&
                  _suggestions!.any((s) => s.suggestions.isNotEmpty)) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: const Color(0xFF3DBEA9),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cours en ligne suggérés',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recommandations selon les notes de votre enfant (matières à renforcer).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._suggestions!.where((r) => r.suggestions.isNotEmpty).map((
                        resp,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pour ${resp.studentName}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF3DBEA9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...resp.suggestions.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.play_circle_outline,
                                        size: 18,
                                        color: Color(0xFF3DBEA9),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.suggestedCourseTitle,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            Text(
                                              '${s.subjectName} · Moyenne ${s.average.toStringAsFixed(1)}/20',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
                const SizedBox(height: 16),
              ],
              // Bloc de synthèse en bas
              Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vue d\'ensemble',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardStatCard(
                                label: 'Présence',
                                value: '$totalAttendance',
                                subtitle: 'Jours ce mois (tous)',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DashboardStatCard(
                                label: 'Moyenne',
                                value: avgGrade != null
                                    ? avgGrade.toStringAsFixed(1)
                                    : '—',
                                subtitle: 'Générale',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DashboardStatCard(
                          label: 'Paiements',
                          value: totalUnpaid > 0
                              ? '${totalPending.toStringAsFixed(0)} CDF'
                              : 'À jour',
                          subtitle: totalUnpaid > 0
                              ? '$totalUnpaid facture(s) en attente'
                              : 'Aucune facture',
                          color: totalUnpaid > 0
                              ? Colors.orange
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (children.length * 60).ms)
                  .slideY(begin: 0.08),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(ThemeData theme, NotificationModel n) {
    final bodyPreview = n.body.length > 100
        ? '${n.body.substring(0, 100)}…'
        : n.body;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DBEA9).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  n.postTypeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF3DBEA9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (n.classroomName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  n.classroomName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            n.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (bodyPreview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bodyPreview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (n.studentName.isNotEmpty)
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
              if (n.studentName.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  'Pour ${n.studentName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (n.teacherName.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    n.teacherName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (n.dueDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'À rendre avant le ${n.dueDate}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF3DBEA9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip {
  const _CategoryChip(this.label, this.icon);
  final String label;
  final IconData icon;
}

const List<_CategoryChip> _categories = [
  _CategoryChip('Math', Icons.calculate_outlined),
  _CategoryChip('Sciences', Icons.science_outlined),
  _CategoryChip('Langues', Icons.translate_outlined),
  _CategoryChip('Design', Icons.palette_outlined),
];

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
