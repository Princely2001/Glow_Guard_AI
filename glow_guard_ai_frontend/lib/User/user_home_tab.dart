import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'user_store.dart';
import 'find_expert_tab.dart';
import 'my_requests_screen.dart';
import 'research_tab.dart';
import 'chatbot_tab.dart';

/// ✅ More attractive + animative User Home (no extra packages)
class UserHomeTab extends StatefulWidget {
  const UserHomeTab({super.key});

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ---------- Background ----------
          const _SoftGradientBg(),
          Positioned(top: -120, left: -90, child: _AnimatedBlob(color: Color(0xFF009688), size: 280, phase: 0.0)),
          Positioned(bottom: -150, right: -110, child: _AnimatedBlob(color: Color(0xFFFF9800), size: 340, phase: 1.1)),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  title: const Text("GlowGuard AI"),
                  actions: [
                    IconButton(
                      tooltip: "My Requests",
                      icon: const Icon(Icons.history),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),

                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------- Hero ----------
                            _HeroCard(
                              onFindExpert: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FindExpertTab()),
                              ),
                              onChatbot: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChatbotTab()),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ---------- Stats row ----------
                            ValueListenableBuilder(
                              valueListenable: userRequestsStore,
                              builder: (context, List<UserTestRequest> reqs, _) {
                                final total = reqs.length;
                                final completed =
                                    reqs.where((r) => r.status == RequestStatus.completed).length;
                                final pending =
                                    reqs.where((r) => r.status != RequestStatus.completed).length;

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _StatChip(
                                        icon: Icons.receipt_long_outlined,
                                        label: "Requests",
                                        value: total,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatChip(
                                        icon: Icons.timelapse_outlined,
                                        label: "Pending",
                                        value: pending,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatChip(
                                        icon: Icons.verified_outlined,
                                        label: "Done",
                                        value: completed,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            // ---------- Quick Actions ----------
                            Row(
                              children: [
                                Text("Quick Actions", style: Theme.of(context).textTheme.titleMedium),
                                const Spacer(),
                                _PillTag(text: "USER", color: cs.primary),
                              ],
                            ),
                            const SizedBox(height: 10),

                            GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.18,
                              ),
                              children: [
                                _ActionTile(
                                  icon: Icons.search_outlined,
                                  title: "Find Expert",
                                  subtitle: "Request a test",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FindExpertTab()),
                                  ),
                                ),
                                _ActionTile(
                                  icon: Icons.history,
                                  title: "My Requests",
                                  subtitle: "Track results",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                                  ),
                                ),
                                _ActionTile(
                                  icon: Icons.school_outlined,
                                  title: "Study",
                                  subtitle: "Chemicals & labels",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ResearchTab()),
                                  ),
                                ),
                                _ActionTile(
                                  icon: Icons.smart_toy_outlined,
                                  title: "Chatbot",
                                  subtitle: "Ask ingredients",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ChatbotTab()),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // ---------- Learn strip (horizontal) ----------
                            Text("Learn Faster", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 118,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _LearnCard(
                                    title: "Mercury",
                                    subtitle: "Why it’s dangerous",
                                    icon: Icons.warning_amber_rounded,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ResearchTab()),
                                    ),
                                  ),
                                  _LearnCard(
                                    title: "Hydroquinone",
                                    subtitle: "Safe usage tips",
                                    icon: Icons.spa_outlined,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ResearchTab()),
                                    ),
                                  ),
                                  _LearnCard(
                                    title: "Steroids",
                                    subtitle: "Hidden risks",
                                    icon: Icons.health_and_safety_outlined,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ResearchTab()),
                                    ),
                                  ),
                                ].map((w) => Padding(padding: const EdgeInsets.only(right: 12), child: w)).toList(),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ---------- Recent Requests ----------
                            Row(
                              children: [
                                Text("Recent Requests", style: Theme.of(context).textTheme.titleMedium),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                                  ),
                                  child: const Text("View all"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ValueListenableBuilder(
                              valueListenable: userRequestsStore,
                              builder: (context, List<UserTestRequest> list, _) {
                                if (list.isEmpty) {
                                  return _EmptyStateCard(
                                    title: "No requests yet",
                                    subtitle: "Tap “Find Expert” to request your first chemical test.",
                                    buttonText: "Find Expert",
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const FindExpertTab()),
                                    ),
                                  );
                                }

                                final show = list.take(3).toList();
                                return Column(
                                  children: List.generate(show.length, (i) {
                                    final r = show[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _AnimatedEntry(
                                        delayMs: 100 + (i * 80),
                                        child: _RequestCard(r: r),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // ---------- Footer tip ----------
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, color: cs.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Tip: When requesting a test, add product name + batch number for faster expert processing.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FindExpertTab()),
        ),
        icon: const Icon(Icons.search),
        label: const Text("Find Expert"),
      ),
    );
  }
}

/// -------------------- UI PARTS --------------------

class _SoftGradientBg extends StatelessWidget {
  const _SoftGradientBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9FBF9),
            Color(0xFFF7FFFD),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double phase;
  const _AnimatedBlob({required this.color, required this.size, required this.phase});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final dy = math.sin((t * math.pi * 2) + phase) * 10;
        final dx = math.cos((t * math.pi * 2) + phase) * 6;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onFindExpert;
  final VoidCallback onChatbot;

  const _HeroCard({
    required this.onFindExpert,
    required this.onChatbot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated icon badge
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              final dy = math.sin(t * math.pi * 2) * 4.5;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withOpacity(0.95),
                        cs.primary.withOpacity(0.70),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        color: cs.primary.withOpacity(0.18),
                      )
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Stay protected", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  "Request chemical tests from experts and learn safe ingredients.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onFindExpert,
                        icon: const Icon(Icons.search),
                        label: const Text("Find Expert"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onChatbot,
                      tooltip: "Chatbot",
                      icon: const Icon(Icons.smart_toy_outlined),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) {
                    return Text(
                      "${v.round()}",
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String text;
  final Color color;
  const _PillTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.05),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withOpacity(0.18)),
                ),
                child: Icon(widget.icon, color: cs.primary),
              ),
              const Spacer(),
              Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _LearnCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_LearnCard> createState() => _LearnCardState();
}

class _LearnCardState extends State<_LearnCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.secondary.withOpacity(0.18)),
                ),
                child: Icon(widget.icon, color: cs.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final UserTestRequest r;
  const _RequestCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final statusColor = switch (r.status) {
      RequestStatus.pending => cs.secondary,
      RequestStatus.inProgress => cs.primary,
      RequestStatus.completed => cs.tertiary,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.18)),
            ),
            child: Icon(Icons.science_outlined, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${r.productName} • ${testTypeLabel(r.testType)}",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  "Expert: ${r.expertName} • ${r.status.name}",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.surfaceContainerHighest, cs.surfaceContainerHighest.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: onPressed, child: Text(buttonText)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
