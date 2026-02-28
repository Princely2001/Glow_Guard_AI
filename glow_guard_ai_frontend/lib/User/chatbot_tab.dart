import 'dart:convert';
import 'dart:ui';
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
  final _inputFocus = FocusNode();

  // messages for UI only
  final List<_UiMsg> _msgs = [
    const _UiMsg(
      me: false,
      text:
      "Hi! I'm GlowGuard Assistant ✨\nI can help you check cosmetic ingredients, bleaching/whitening products, and safety risks.",
    ),
  ];

  // history for backend / LLM context
  final List<Map<String, String>> _history = [
    {
      "role": "assistant",
      "content":
      "Hi! I'm GlowGuard Assistant. Ask me about cosmetics ingredients or bleaching/whitening products."
    },
  ];

  bool _sending = false;

  // Suggested prompts (rotating sets)
  int _promptSetIndex = 0;
  final List<List<String>> _promptSets = const [
    [
      "Is hydroquinone safe for skin?",
      "What are signs of mercury in face creams?",
      "Check if steroids are used in whitening creams",
      "Which ingredients should I avoid during pregnancy?",
    ],
    [
      "What does kojic acid do for skin?",
      "Is niacinamide safe for daily use?",
      "Can I mix retinol with vitamin C?",
      "Which ingredients can irritate sensitive skin?",
    ],
    [
      "How to identify counterfeit whitening products?",
      "What are harmful bleaching ingredients?",
      "How to read a cosmetic ingredient label?",
      "What are safer alternatives to skin bleaching creams?",
    ],
    [
      "What side effects can hydroquinone cause?",
      "Is mercury allowed in cosmetics?",
      "How long should I use a brightening product?",
      "What should I do if a cream causes burning or redness?",
    ],
  ];

  // Android emulator: http://10.0.2.2:8081
  // iOS simulator: http://127.0.0.1:8081
  // Real device:    http://<your-pc-lan-ip>:8081
  static const String _baseUrl = "http://10.0.2.2:8081";

  @override
  void dispose() {
    _c.dispose();
    _scrollC.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _msgs.add(_UiMsg(me: true, text: t));
      _history.add({"role": "user", "content": t});
      _msgs.add(const _UiMsg(me: false, text: "Typing…", typing: true));
    });

    _c.clear();
    _jumpToBottomSoon();

    try {
      final reply = await _fetchReply(message: t, history: _history);

      setState(() {
        _msgs.removeWhere((m) => m.typing);
        _msgs.add(_UiMsg(me: false, text: reply));
        _history.add({"role": "assistant", "content": reply});
        _sending = false;
      });
      _jumpToBottomSoon();
    } catch (e) {
      setState(() {
        _msgs.removeWhere((m) => m.typing);
        _msgs.add(
          _UiMsg(
            me: false,
            text: "Sorry — I couldn't reach the server. (${e.toString()})",
          ),
        );
        _history.add({
          "role": "assistant",
          "content": "Sorry — I couldn't reach the server."
        });
        _sending = false;
      });
      _jumpToBottomSoon();
    }
  }

  Future<void> _sendPrompt(String prompt) async {
    if (_sending) return;
    _c.text = prompt;
    _c.selection = TextSelection.fromPosition(
      TextPosition(offset: _c.text.length),
    );
    await _send();
  }

  void _rotatePrompts() {
    setState(() {
      _promptSetIndex = (_promptSetIndex + 1) % _promptSets.length;
    });
  }

  Future<String> _fetchReply({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final url = Uri.parse("$_baseUrl/chat");

    // send only last N turns to reduce token usage
    const maxTurns = 12;
    final trimmedHistory = history.length <= maxTurns
        ? history
        : history.sublist(history.length - maxTurns);

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
      final max = _scrollC.position.maxScrollExtent;
      _scrollC.animateTo(
        max + 220,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentPrompts = _promptSets[_promptSetIndex];
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Dynamic top spacing so first message is never hidden under app bar/notch
    final topSafe = MediaQuery.of(context).padding.top;
    final topHeaderSpace = topSafe + kToolbarHeight + 8;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 14,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "GlowGuard Assistant",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _sending ? "Typing..." : "Cosmetics Safety Chatbot",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(0.15),
                      cs.secondary.withOpacity(0.10),
                      cs.surface.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withOpacity(0.05),
              cs.secondary.withOpacity(0.04),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: topHeaderSpace),

            // Messages take maximum space
            Expanded(
              child: ListView.builder(
                controller: _scrollC,
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  final isWelcomeCard = i == 0 && !m.me;

                  return _AnimatedChatBubble(
                    key: ValueKey("msg_${i}_${m.typing}_${m.text.hashCode}"),
                    message: m,
                    colorScheme: cs,
                    isWelcomeCard: isWelcomeCard,
                  );
                },
              ),
            ),

            // Bottom area (suggestions + composer)
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hide suggestions while keyboard is open (prevents crowding)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: keyboardOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _SuggestedPromptsPanel(
                      prompts: currentPrompts,
                      onPromptTap: _sendPrompt,
                      onRefresh: _rotatePrompts,
                      enabled: !_sending,
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  _Composer(
                    controller: _c,
                    focusNode: _inputFocus,
                    sending: _sending,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedPromptsPanel extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onPromptTap;
  final VoidCallback onRefresh;
  final bool enabled;

  const _SuggestedPromptsPanel({
    required this.prompts,
    required this.onPromptTap,
    required this.onRefresh,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Try asking",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Refresh prompts",
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled ? onRefresh : null,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return _PromptChip(
                    text: prompts[i],
                    onTap: enabled ? () => onPromptTap(prompts[i]) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  const _PromptChip({
    required this.text,
    required this.onTap,
  });

  @override
  State<_PromptChip> createState() => _PromptChipState();
}

class _PromptChipState extends State<_PromptChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.10),
                  cs.secondary.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: cs.primary.withOpacity(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_outlined, size: 15, color: cs.primary),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12.8,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: "Ask about hydroquinone, mercury, steroids…",
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.55)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: sending
                      ? [
                    cs.outline.withOpacity(0.45),
                    cs.outline.withOpacity(0.25),
                  ]
                      : [
                    cs.primary,
                    cs.secondary,
                  ],
                ),
                boxShadow: sending
                    ? []
                    : [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: sending ? null : onSend,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: sending
                      ? const SizedBox(
                    key: ValueKey("loading"),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(
                    Icons.arrow_upward_rounded,
                    key: ValueKey("send"),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedChatBubble extends StatefulWidget {
  final _UiMsg message;
  final ColorScheme colorScheme;
  final bool isWelcomeCard;

  const _AnimatedChatBubble({
    super.key,
    required this.message,
    required this.colorScheme,
    this.isWelcomeCard = false,
  });

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fade = CurvedAnimation(
      parent: _ac,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin:
      widget.message.me ? const Offset(0.16, 0) : const Offset(-0.16, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
    );

    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final cs = widget.colorScheme;
    final isMe = m.me;

    // Special welcome card for the very first assistant message
    if (widget.isWelcomeCard && !m.typing) {
      return FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withOpacity(0.10),
                    cs.secondary.withOpacity(0.08),
                    cs.surface.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.primary.withOpacity(0.16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to GlowGuard",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.8,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.text,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.88),
                            fontSize: 13.6,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bubbleGradient = isMe
        ? LinearGradient(
      colors: [
        cs.primary.withOpacity(0.95),
        cs.secondary.withOpacity(0.90),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : LinearGradient(
      colors: [
        cs.surfaceVariant.withOpacity(0.55),
        cs.surface.withOpacity(0.95),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withOpacity(0.12),
                    border: Border.all(color: cs.primary.withOpacity(0.22)),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: bubbleGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 18),
                    ),
                    border: Border.all(
                      color: isMe
                          ? Colors.white.withOpacity(0.15)
                          : cs.outline.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isMe ? 0.10 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: m.typing
                      ? _TypingDots(color: isMe ? Colors.white : cs.primary)
                      : Text(
                    m.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : cs.onSurface,
                      height: 1.35,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondary.withOpacity(0.12),
                    border: Border.all(color: cs.secondary.withOpacity(0.22)),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: cs.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 18,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (context, _) {
          double phase(int i) => ((_ac.value + i * 0.18) % 1.0);

          double scaleFromPhase(double p) {
            final v = (0.5 - (p - 0.5).abs()) * 2; // 0..1..0
            return 0.75 + (v * 0.45);
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(3, (i) {
              final s = scaleFromPhase(phase(i));
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Transform.scale(
                  scale: s,
                  child: Opacity(
                    opacity: (s - 0.7).clamp(0.35, 1.0),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _UiMsg {
  final bool me;
  final String text;
  final bool typing;

  const _UiMsg({
    required this.me,
    required this.text,
    this.typing = false,
  });
}