library;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/teacher_remote_datasource.dart';

class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  final _authLocal = AuthLocalDataSource();
  List<Map<String, dynamic>> _conversations = const [];
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
      final data = await ds.getMyConversations();
      if (!mounted) return;
      setState(() {
        _conversations = data;
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

  Future<void> _openConversation(Map<String, dynamic> conv) async {
    final ds = await _ds();
    if (ds == null) return;
    final convId = (conv['id'] as num).toInt();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TeacherConversationScreen(
          conversationId: convId,
          title: '${conv['title'] ?? 'Conversation'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Messages', style: theme.textTheme.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Messages', style: theme.textTheme.titleMedium),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: theme.textTheme.titleMedium),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = _conversations[i];
            final title = '${c['title'] ?? 'Conversation'}';
            final preview = (c['last_preview'] as String?) ?? '';
            final school = (c['school_name'] as String?) ?? '';
            return Card(
              child: ListTile(
                title: Text(title, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  '${school.isNotEmpty ? '$school • ' : ''}$preview',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openConversation(c),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TeacherConversationScreen extends StatefulWidget {
  const _TeacherConversationScreen({
    required this.conversationId,
    required this.title,
  });

  final int conversationId;
  final String title;

  @override
  State<_TeacherConversationScreen> createState() =>
      _TeacherConversationScreenState();
}

class _TeacherConversationScreenState
    extends State<_TeacherConversationScreen> {
  final _authLocal = AuthLocalDataSource();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = const [];
  String? _error;
  bool _loading = true;
  bool _sending = false;

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
          _error = 'Session expirée.';
          _loading = false;
        });
        return;
      }
      final data = await ds.getConversationMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = data;
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final ds = await _ds();
      if (ds == null) return;
      final msg = await ds.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
        _controller.clear();
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMine = (m['is_mine'] as bool?) ?? false;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: isMine
                                ? theme.colorScheme.primary
                                : const Color(0xFFF5F6F7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${m['body'] ?? ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isMine
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
