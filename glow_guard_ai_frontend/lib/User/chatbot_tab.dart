import 'package:flutter/material.dart';

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final _c = TextEditingController();
  final List<(bool me, String text)> _msgs = [
    (false, "Hi! I'm GlowGuard Assistant. Ask me about harmful chemicals or ingredients."),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;

    setState(() {
      _msgs.add((true, t));
      _msgs.add((false, _reply(t)));
    });
    _c.clear();
  }

  String _reply(String t) {
    final x = t.toLowerCase();
    if (x.contains("mercury")) return "Mercury is toxic. Avoid unregulated whitening creams.";
    if (x.contains("hydroquinone")) return "Hydroquinone may irritate skin; use only with guidance.";
    if (x.contains("steroid")) return "Hidden steroids can thin skin and cause long-term effects.";
    if (x.contains("safe")) return "Often safe: glycerin, ceramides, niacinamide (depends on skin type).";
    return "Ask about: mercury, hydroquinone, steroids, safe ingredients, label reading.";
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
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final (me, text) = _msgs[i];
                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: me ? cs.primaryContainer : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(text),
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
                        hintText: "Ask about chemicals...",
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
