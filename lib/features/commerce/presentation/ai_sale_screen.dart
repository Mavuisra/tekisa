library;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/models/commerce_models.dart';

class AiSaleScreen extends StatefulWidget {
  const AiSaleScreen({super.key});

  @override
  State<AiSaleScreen> createState() => _AiSaleScreenState();
}

class _AiSaleScreenState extends State<AiSaleScreen> {
  final _authLocal = AuthLocalDataSource();
  final _controller = TextEditingController();
  final List<_AiBubble> _messages = <_AiBubble>[
    const _AiBubble(
      text:
          'Bonjour 👋 Décris la vente en langage naturel.\nEx: "vends 2 coca et 1 sucre, client Jean, paiement cash".',
      isUser: false,
    ),
  ];
  bool _loading = false;
  AiSaleDraftModel? _lastDraft;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListeningVoice = false;
  String _lastRecognizedText = '';
  bool _isDisposed = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<CommerceRemoteDataSource?> _source() async {
    final token = await _authLocal.getAccessToken();
    if (token == null || token.isEmpty) return null;
    final client = DioClient(
      baseUrl: EnvConfig.apiBaseUrl,
      accessToken: token,
      getRefreshToken: () => _authLocal.getRefreshToken(),
      saveAccessToken: (t) => _authLocal.setAccessToken(t),
    );
    return CommerceRemoteDataSource(client);
  }

  Future<void> _sendPrompt() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_AiBubble(text: text, isUser: true));
      _controller.clear();
      _loading = true;
    });
    final source = await _source();
    if (source == null) {
      setState(() {
        _messages.add(
          const _AiBubble(
            text: 'Session expirée. Reconnecte-toi puis réessaie.',
            isUser: false,
          ),
        );
        _loading = false;
      });
      return;
    }
    try {
      final draft = await source.getAiSaleDraft(prompt: text);
      final itemCount = draft.items.length;
      final unmatched = draft.unmatched.length;
      setState(() {
        _lastDraft = draft;
        _messages.add(
          _AiBubble(
            text:
                'Brouillon prêt: $itemCount article(s) reconnu(s), $unmatched non reconnu(s). Vérifie puis confirme.',
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _AiBubble(
            text: 'Erreur IA: ${e.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _safeSetState(() => _isListeningVoice = false);
        }
      },
      onError: (_) {
        _safeSetState(() => _isListeningVoice = false);
      },
    );
    _safeSetState(() {});
  }

  Future<void> _toggleVoiceInput() async {
    if (_loading) return;
    if (!_speechReady) {
      await _initSpeech();
      if (!mounted) return;
      if (!_speechReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconnaissance vocale indisponible sur cet appareil.')),
        );
        return;
      }
    }

    if (_isListeningVoice) {
      await _stopVoiceInput();
      return;
    }
    _lastRecognizedText = '';
    final started = await _speech.listen(
      localeId: 'fr_FR',
      listenFor: const Duration(seconds: 25),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        _lastRecognizedText = words;
        _safeSetState(() {
          _controller.text = words;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
    if (!mounted) return;
    if (started != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer le micro. Vérifie les permissions.')),
      );
      return;
    }
    _safeSetState(() {
      _isListeningVoice = true;
    });
  }

  Future<void> _stopVoiceInput() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListeningVoice = false);
    final text = _lastRecognizedText.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun texte détecté.')),
      );
      return;
    }
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _confirmDraft() async {
    final draft = _lastDraft;
    if (draft == null || draft.items.isEmpty || _loading) return;
    setState(() => _loading = true);
    final source = await _source();
    if (source == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final receipt = await source.createQuickSale(
        items: draft.items
            .map((e) => CartItemInput(productId: e.productId, quantity: e.quantity))
            .toList(),
        paymentMethod: draft.paymentMethod,
        discountRate: 0,
        customerName: draft.customerName,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiBubble(
            text:
                'Vente enregistrée ✅ Reçu #${receipt.id} • Total ${receipt.total.toStringAsFixed(0)} CDF',
            isUser: false,
          ),
        );
        _lastDraft = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiBubble(
            text: 'Impossible de valider: ${e.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendre avec IA'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFECE5DD),
              child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              itemCount: _messages.length + (_lastDraft != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (_lastDraft != null && index == _messages.length) {
                  return _DraftCard(
                    draft: _lastDraft!,
                    onConfirm: _loading ? null : _confirmDraft,
                  );
                }
                final m = _messages[index];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? const Color(0xFFDCF8C6)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(m.isUser ? 14 : 4),
                        bottomRight: Radius.circular(m.isUser ? 4 : 14),
                      ),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                children: [
                  IconButton(
                    onPressed: _loading ? null : _toggleVoiceInput,
                    tooltip: 'Envoyer un vocal à l’IA',
                    icon: Icon(
                      _isListeningVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: _isListeningVoice ? Colors.redAccent : null,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendPrompt(),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _loading ? null : _sendPrompt,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble {
  const _AiBubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.onConfirm});

  final AiSaleDraftModel draft;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18),
              SizedBox(width: 6),
              Text('Brouillon IA', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...draft.items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text('${e.name} x${e.quantity}')),
                  Text('${e.lineTotal.toStringAsFixed(0)} CDF'),
                ],
              ),
            ),
          ),
          if (draft.unmatched.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text('Non reconnus:', style: TextStyle(fontWeight: FontWeight.w600)),
            ...draft.unmatched.map((u) => Text('- ${u.text}')),
          ],
          if (draft.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...draft.warnings.map(
              (w) => Text(
                '⚠ $w',
                style: const TextStyle(color: Color(0xFF92400E)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Paiement: ${draft.paymentMethod} • Client: ${draft.customerName.isEmpty ? 'Client libre' : draft.customerName}',
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${draft.total.toStringAsFixed(0)} CDF',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Confirmer la vente'),
          ),
        ],
      ),
    );
  }
}
