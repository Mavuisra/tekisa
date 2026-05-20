library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/support/support_contact.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';
import '../../auth/data/django_auth_service.dart';
import '../../auth/presentation/auth_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  String? _displayName;
  String? _phone;
  String? _role;
  bool _posting = false;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = _authLocal.getUser();
    if (user != null) {
      setState(() {
        _displayName = user.displayName ?? user.username ?? user.phone;
        _phone = user.phone;
        _role = user.role;
        _themeMode = ThemeController.instance.themeMode;
      });
    }
  }

  Future<TeacherRemoteDataSource?> _teacherDs() async {
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

  Future<void> _openTeacherPostSheet() async {
    final theme = Theme.of(context);
    final ds = await _teacherDs();
    if (ds == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée. Reconnectez-vous.')),
      );
      return;
    }

    List<Map<String, dynamic>> classes = const [];
    try {
      final data = await ds.getMyClasses();
      classes = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(RegExp(r'^Exception: '), '')),
        ),
      );
      return;
    }

    if (classes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune classe trouvée pour créer une publication.'),
        ),
      );
      return;
    }

    String type = 'assignment';
    int selectedClassId = (classes.first)['id'] as int;
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
                      'Créez un devoir, un exercice ou une annonce pour informer rapidement les parents.',
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
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: (c)['id'] as int,
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
                                  await ds.createPost(
                                    type: type,
                                    classroomId: selectedClassId,
                                    title: title,
                                    body: body,
                                    dueDate: dueDate,
                                  );
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Publication envoyée aux parents de la classe sélectionnée.',
                                        ),
                                      ),
                                    );
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

  Future<void> _contactSupport() async {
    final opened = await openWhatsAppSupport();
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Impossible d\'ouvrir WhatsApp. Vérifiez votre appareil.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _displayName != null || _phone != null
        ? '${_displayName ?? ''}${_phone != null ? ' · $_phone' : ''}'.trim()
        : 'Nom, numéro de téléphone, langue';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        actions: [
          IconButton(
            onPressed: () async {
              await djangoAuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthRouter()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(
              ((_role ?? '').toLowerCase() == 'teacher')
                  ? 'Profil enseignant'
                  : 'Profil du parent',
            ),
            subtitle: Text(subtitle),
            onTap: () {},
          ),
          if ((_role ?? '').toLowerCase() == 'teacher') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Espace enseignant',
                style: theme.textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.post_add_outlined),
              title: const Text('Créer un devoir / annonce'),
              subtitle: const Text(
                'Informer immédiatement les parents de la classe.',
              ),
              onTap: _openTeacherPostSheet,
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Thème'),
            subtitle: DropdownButtonFormField<ThemeMode>(
              initialValue: _themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Système'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _themeMode = value);
                await ThemeController.instance.setThemeMode(value);
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir les alertes importantes'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined),
            title: const Text('SMS importants'),
            subtitle: const Text('Absences, paiements, résultats'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.offline_pin_outlined),
            title: const Text('Mode hors-ligne'),
            subtitle: const Text(
              'Les données récentes sont disponibles sans internet',
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Contacter le support WhatsApp'),
            subtitle: const Text('Assistance directe en cas de souci'),
            onTap: _contactSupport,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'CisnetKids • v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
