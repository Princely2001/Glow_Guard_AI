import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_store.dart';
import 'find_expert_tab.dart';
import 'View_Test_Results.dart';
import 'research_tab.dart';
import 'chatbot_tab.dart';
import 'profile_tab.dart';
import 'ProductReportScreen.dart';

//Design tokens
class _Tokens {
  static const teal = Color(0xFF00897B);
  static const tealLight = Color(0xFFE0F2F1);
  static const tealDark = Color(0xFF00695C);
  static const amber = Color(0xFFFF8F00);
  static const amberLight = Color(0xFFFFF8E1);
  static const surface = Color(0xFFF7FAFA);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0EEEC);
  static const textPrimary = Color(0xFF0D2220);
  static const textSecondary = Color(0xFF4A6B67);
  static const textHint = Color(0xFF8AABAA);
  static const divider = Color(0xFFECF3F2);

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border, width: 1),
    boxShadow: [
      BoxShadow(
        color: teal.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

// Entry point
class UserHomeTab extends StatefulWidget {
  const UserHomeTab({super.key});

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.surface,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -80,
            child: _Blob(color: _Tokens.teal, size: 300, phase: 0),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _Blob(color: _Tokens.amber, size: 280, phase: 1.2),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App bar
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      backgroundColor: Colors.transparent,
                      centerTitle: false,
                      toolbarHeight: 58,
                      title: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_Tokens.teal, _Tokens.tealDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'GlowGuard',
                            style: TextStyle(
                              color: _Tokens.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            ' AI',
                            style: TextStyle(
                              color: _Tokens.teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        _NotificationIcon(onViewAll: () => _push(const MyRequestsScreen())),
                        const SizedBox(width: 12),
                      ],
                    ),

                    // Body
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Profile header
                          _ProfileCard(onTap: () => _push(const ProfileTab())),
                          const SizedBox(height: 16),

                          // Hero banner
                          _HeroBanner(
                            onFindExpert: () => _push(const FindExpertTab()),
                            onChatbot: () => _push(const ChatbotTab()),
                          ),
                          const SizedBox(height: 20),

                          // Stats row
                          ValueListenableBuilder<List<UserTestRequest>>(
                            valueListenable: userRequestsStore,
                            builder: (_, reqs, __) => _StatsRow(
                              total: reqs.length,
                              pending: reqs.where((r) => r.status != RequestStatus.completed).length,
                              completed: reqs.where((r) => r.status == RequestStatus.completed).length,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section: Quick Actions
                          _SectionLabel(title: 'Quick Actions', badge: 'USER'),
                          const SizedBox(height: 12),
                          _ActionsGrid(
                            items: [
                              _ActionItem(
                                icon: Icons.report_problem_outlined,
                                label: 'Report Harmful',
                                sub: 'Track side effects',
                                onTap: () => _push(const DangerousProductReportScreen()),
                              ),
                              _ActionItem(
                                icon: Icons.history_rounded,
                                label: 'Test Results',
                                sub: 'View your results',
                                onTap: () => _push(const MyRequestsScreen()),
                              ),
                              _ActionItem(
                                icon: Icons.school_outlined,
                                label: 'Research',
                                sub: 'Chemicals & labels',
                                onTap: () => _push(const ResearchTab()),
                              ),
                              _ActionItem(
                                icon: Icons.smart_toy_outlined,
                                label: 'AI Chatbot',
                                sub: 'Ask ingredients',
                                onTap: () => _push(const ChatbotTab()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Section: Learn Faster
                          _SectionLabel(title: 'Learn Faster'),
                          const SizedBox(height: 12),
                          _LearnRow(onTap: () => _push(const ResearchTab())),
                          const SizedBox(height: 24),

                          // Section: Recent Requests
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent Requests',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _Tokens.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _push(const MyRequestsScreen()),
                                style: TextButton.styleFrom(
                                  foregroundColor: _Tokens.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('View all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<List<UserTestRequest>>(
                            valueListenable: userRequestsStore,
                            builder: (_, list, __) {
                              if (list.isEmpty) {
                                return _EmptyState(
                                  onTap: () => _push(const FindExpertTab()),
                                );
                              }
                              return Column(
                                children: list
                                    .take(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.key < 2 ? 8 : 0,
                                    ),
                                    child: _AnimatedEntry(
                                      delayMs: 80 * e.key,
                                      child: _RequestRow(r: e.value),
                                    ),
                                  ),
                                )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Tip card
                          const _TipBanner(),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(const FindExpertTab()),
        backgroundColor: _Tokens.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.search_rounded),
        label: const Text(
          'Find Expert',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
    );
  }
}

// Background blob
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double phase;
  const _Blob({required this.color, required this.size, required this.phase});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 2 * math.pi),
      duration: const Duration(seconds: 8),
      curve: Curves.linear,
      builder: (_, t, __) => Transform.translate(
        offset: Offset(
          math.cos(t + phase) * 8,
          math.sin(t + phase) * 6,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

//Notification icon
class _NotificationIcon extends StatelessWidget {
  final VoidCallback onViewAll;
  const _NotificationIcon({required this.onViewAll});

  void _showDialog(BuildContext context, List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _Tokens.tealLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.biotech_rounded, color: _Tokens.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lab Results Ready',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _Tokens.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: _Tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copy your Record ID and paste it in the search screen to view the full report.',
                  style: TextStyle(fontSize: 13, color: _Tokens.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final id = d['recordId']?.toString() ?? docs[i].id;
                      final type = d['testType']?.toString() ?? 'Test';
                      final label = d['predictionLabel']?.toString() ?? 'Result';
                      return Container(
                        decoration: BoxDecoration(
                          color: _Tokens.tealLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _Tokens.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: SelectableText(
                            id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _Tokens.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '$type · $label',
                            style: const TextStyle(fontSize: 12, color: _Tokens.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.copy_rounded, size: 18, color: _Tokens.teal),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: id));
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('ID copied!')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onViewAll();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _Tokens.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Go to Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.history_rounded),
        onPressed: onViewAll,
        style: IconButton.styleFrom(foregroundColor: _Tokens.textPrimary),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chemical test private')
          .where('requestedUserId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? [])
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'] as Timestamp?;
            final bt = (b.data() as Map)['createdAt'] as Timestamp?;
            return (bt?.compareTo(at ?? Timestamp.now()) ?? 0);
          });
        final recent = docs.take(5).toList();

        return Badge(
          isLabelVisible: recent.isNotEmpty,
          label: Text('${recent.length}'),
          offset: const Offset(-4, 4),
          child: IconButton(
            tooltip: 'Lab Results',
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(foregroundColor: _Tokens.textPrimary),
            onPressed: () {
              if (recent.isNotEmpty) {
                _showDialog(context, recent);
              } else {
                onViewAll();
              }
            },
          ),
        );
      },
    );
  }
}

//Profile card
class _ProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = data['name']?.toString() ?? 'User';
        final userId = data['userId']?.toString() ?? '';
        final photoUrl = data['photoUrl']?.toString() ?? '';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _Tokens.teal.withOpacity(0.08),
                    _Tokens.teal.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _Tokens.teal.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_Tokens.teal, _Tokens.tealDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: CircleAvatar(
                      backgroundColor: _Tokens.cardBg,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Icon(Icons.person_rounded, color: _Tokens.teal, size: 26)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name + ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _Tokens.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Pill(label: 'USER'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userId.isEmpty ? 'Tap to view profile' : 'ID: $userId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _Tokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.manage_accounts_outlined, size: 14, color: _Tokens.teal),
                            const SizedBox(width: 4),
                            const Text(
                              'View & edit profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: _Tokens.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _Tokens.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _Tokens.border),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _Tokens.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Pill
class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _Tokens.teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Tokens.teal.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _Tokens.teal,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

//Hero banner
class _HeroBanner extends StatelessWidget {
  final VoidCallback onFindExpert;
  final VoidCallback onChatbot;
  const _HeroBanner({required this.onFindExpert, required this.onChatbot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_Tokens.teal, _Tokens.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Tokens.teal.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stay protected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request chemical tests from verified experts and learn about safe cosmetic ingredients.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  onTap: onFindExpert,
                  icon: Icons.search_rounded,
                  label: 'Find Expert',
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              _HeroButton(
                onTap: onChatbot,
                icon: Icons.smart_toy_outlined,
                label: 'Chatbot',
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool filled;
  const _HeroButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? _Tokens.tealDark : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? _Tokens.tealDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Stats row
class _StatsRow extends StatelessWidget {
  final int total;
  final int pending;
  final int completed;
  const _StatsRow({required this.total, required this.pending, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip(icon: Icons.receipt_long_outlined, label: 'Total', value: total, color: _Tokens.teal)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.timelapse_outlined, label: 'Pending', value: pending, color: _Tokens.amber)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.check_circle_outline_rounded, label: 'Done', value: completed, color: const Color(0xFF2E7D32))),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _Tokens.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.round()}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _Tokens.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

//Section label
class _SectionLabel extends StatelessWidget {
  final String title;
  final String? badge;
  const _SectionLabel({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _Tokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (badge != null) _Pill(label: badge!),
      ],
    );
  }
}

//Quick Actions grid
class _ActionItem {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
}

class _ActionsGrid extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    // Always 2 columns for consistency and readability
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ActionTile(item: items[i]),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _Tokens.card(radius: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _Tokens.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.item.icon, color: _Tokens.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _Tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Learn row (horizontal scroll)
class _LearnRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LearnRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.warning_amber_rounded, title: 'Mercury', sub: 'Why it\'s dangerous', color: const Color(0xFFB71C1C)),
      (icon: Icons.spa_outlined, title: 'Hydroquinone', sub: 'Safe usage tips', color: _Tokens.teal),
      (icon: Icons.health_and_safety_outlined, title: 'Steroids', sub: 'Hidden risks', color: _Tokens.amber),
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return _LearnCard(
            icon: item.icon,
            title: item.title,
            sub: item.sub,
            color: item.color,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _LearnCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _LearnCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LearnCard> createState() => _LearnCardState();
}

class _LearnCardState extends State<_LearnCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(14),
          decoration: _Tokens.card(radius: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _Tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Request row
String _label(Object? v) {
  if (v == null) return '-';
  final s = v.toString();
  return s.contains('.') ? s.split('.').last : s;
}

class _RequestRow extends StatelessWidget {
  final UserTestRequest r;
  const _RequestRow({required this.r});

  Color get _statusColor {
    switch (r.status) {
      case RequestStatus.pending:
        return _Tokens.amber;
      case RequestStatus.inProgress:
        return _Tokens.teal;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _Tokens.card(radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.science_outlined, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.productName} · ${_label(r.testType)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Expert: ${r.expertName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _Tokens.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _label(r.status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//Empty state
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: _Tokens.card(radius: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _Tokens.tealLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inbox_outlined, color: _Tokens.teal, size: 26),
          ),
          const SizedBox(height: 12),
          const Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _Tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Find Expert" to request your first chemical test.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _Tokens.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Find Expert'),
            style: FilledButton.styleFrom(
              backgroundColor: _Tokens.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// Tip banner
class _TipBanner extends StatelessWidget {
  const _TipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Tokens.amberLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Tokens.amber.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: _Tokens.amber, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tip: When requesting a test, add the product name and batch number for faster expert processing.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF5D4037),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated entry
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
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