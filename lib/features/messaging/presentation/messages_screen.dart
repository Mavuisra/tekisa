library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/env_config.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/parent_data_remote_datasource.dart';
import '../../../data/models/conversation_model.dart';
import '../../../core/network/dio_client.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  List<ConversationModel> _conversations = [];
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
      final list = await ds.getMyConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
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

  void _onNewMessage() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouveau message',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un destinataire (direction, enseignant) pour commencer une conversation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.person_search),
              label: const Text('Choisir un destinataire'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
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
          title: const Text('Messages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nouveau message',
              onPressed: _onNewMessage,
            ),
          ],
        ),
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
                  height: 60,
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
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nouveau message',
              onPressed: _onNewMessage,
            ),
          ],
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
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau message',
            onPressed: _onNewMessage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _conversations.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DBEA9).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: Color(0xFF3DBEA9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune conversation.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final c = _conversations[index];
                  final title = c.title.isNotEmpty ? c.title : c.schoolName;
                  final preview = c.lastPreview.isNotEmpty
                      ? c.lastPreview
                      : 'Aucun message';
                  String time = '';
                  if (c.lastMessageAt != null &&
                      c.lastMessageAt!.length >= 19) {
                    final dt = c.lastMessageAt!;
                    time = dt.substring(0, 10);
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (title.isNotEmpty ? title : '?').characters.first
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(title.isNotEmpty ? title : 'Conversation'),
                    subtitle: Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(time, style: theme.textTheme.bodySmall),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: c.id,
                          title: title.isNotEmpty ? title : 'Messages',
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final int conversationId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthLocalDataSource _authLocal = AuthLocalDataSource();
  List<ConversationMessageModel> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final token = await _authLocal.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final client = DioClient(
        baseUrl: EnvConfig.apiBaseUrl,
        accessToken: token,
        getRefreshToken: () => _authLocal.getRefreshToken(),
        saveAccessToken: (t) => _authLocal.setAccessToken(t),
      );
      final ds = ParentDataRemoteDataSource(client);
      final list = await ds.getConversationMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _messages
                        .map(
                          (m) => _MessageBubble(text: m.body, isMine: m.isMine),
                        )
                        .toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isMine});
  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final color = isMine
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade200;
    final textColor = isMine ? Colors.white : Colors.black87;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
