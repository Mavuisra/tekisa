library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/env_config.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/parent_data_remote_datasource.dart';
import '../../../data/models/grades_model.dart';
import '../../../core/network/dio_client.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  List<TermResultModel> _termResults = [];
  List<GradeModel> _grades = [];
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
      final results = await ds.getMyTermResults();
      final grades = await ds.getMyGrades();
      if (mounted) {
        setState(() {
          _termResults = results;
          _grades = grades;
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
        appBar: AppBar(title: const Text('Notes et bulletins')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notes et bulletins')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Notes et bulletins')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Moyennes par trimestre', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_termResults.isEmpty)
              Text(
                'Aucune moyenne enregistrée pour vos enfants.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              )
            else
              ..._termResults
                  .take(20)
                  .map(
                    (r) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.studentName,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              '${r.termName} · ${r.schoolName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Moyenne: ${r.averageScore.toStringAsFixed(1)}/20',
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (r.rankInClass != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    'Rang: ${r.rankInClass}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            LinearProgressIndicator(
                              value: (r.averageScore / 20).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            Text('Dernières notes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_grades.isEmpty)
              Text(
                'Aucune note détaillée pour le moment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              )
            else
              ..._grades
                  .take(30)
                  .map(
                    (g) => Card(
                      child: ListTile(
                        title: Text(
                          g.title.isNotEmpty ? g.title : g.subjectName,
                        ),
                        subtitle: Text(
                          '${g.studentName} · ${g.score.toStringAsFixed(1)}/${g.maxScore.toStringAsFixed(0)}'
                          '${g.date != null ? " · ${g.date}" : ""}',
                        ),
                        trailing: Text(
                          '${g.score.toStringAsFixed(1)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: g.score >= 10 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Voir les bulletins PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
