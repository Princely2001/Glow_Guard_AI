import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final _c = TextEditingController();
  final _scrollC = ScrollController();

  // messages for UI only
  final List<_UiMsg> _msgs = [
    _UiMsg(me: false, text: "Hi! I'm GlowGuard Assistant. Ask me about cosmetics ingredients or bleaching/whitening products."),
  ];

  // history for backend / LLM context
  final List<Map<String, String>> _history = [
    {"role": "assistant", "content": "Hi! I'm GlowGuard Assistant. Ask me about cosmetics ingredients or bleaching/whitening products."},
  ];

  bool _sending = false;

  // ✅ CHANGE THIS to your backend address
  // Android emulator: http://10.0.2.2:8080
  // iOS simulator: http://127.0.0.1:8080
  // Real device:    http://<your-pc-lan-ip>:8080
  static const String _baseUrl = "http://10.0.2.2:8080";

  @override
  void dispose() {
    _c.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _msgs.add(_UiMsg(me: true, text: t));
      _history.add({"role": "user", "content": t});
      _msgs.add(_UiMsg(me: false, text: "Typing…", typing: true));
    });
    _c.clear();
    _jumpToBottomSoon();

    try {
      final reply = await _fetchReply(message: t, history: _history);

      setState(() {
        // remove typing bubble
        _msgs.removeWhere((m) => m.typing);
        _msgs.add(_UiMsg(me: false, text: reply));
        _history.add({"role": "assistant", "content": reply});
        _sending = false;
      });
      _jumpToBottomSoon();
    } catch (e) {
      setState(() {
        _msgs.removeWhere((m) => m.typing);
        _msgs.add(_UiMsg(me: false, text: "Sorry — I couldn't reach the server. (${e.toString()})"));
        _history.add({"role": "assistant", "content": "Sorry — I couldn't reach the server."});
        _sending = false;
      });
      _jumpToBottomSoon();
    }
  }

  Future<String> _fetchReply({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final url = Uri.parse("$_baseUrl/chat");

    // send only last N turns to reduce token usage (optional)
    const maxTurns = 12;
    final trimmedHistory = history.length <= maxTurns ? history : history.sublist(history.length - maxTurns);

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "history": trimmedHistory,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("HTTP ${resp.statusCode}: ${resp.body}");
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final reply = (decoded["reply"] ?? "").toString();
    if (reply.trim().isEmpty) throw Exception("Empty reply");
    return reply;
  }

  void _jumpToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollC.hasClients) return;
      _scrollC.animateTo(
        _scrollC.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollC,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: m.me ? cs.primaryContainer : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(m.text),
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
                      controller: _c,
                      decoration: InputDecoration(
                        hintText: "Ask about ingredients (e.g., hydroquinone, mercury)…",
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
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

class _UiMsg {
  final bool me;
  final String text;
  final bool typing;
  const _UiMsg({required this.me, required this.text, this.typing = false});
}
