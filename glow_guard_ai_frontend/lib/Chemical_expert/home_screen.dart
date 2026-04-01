import 'package:flutter/material.dart';

// ✅ Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/results_store.dart';
import '../models/test_models.dart';

import '../widgets/home_widgets.dart';
import '../widgets/common_widgets.dart';

import 'test_screen.dart';
import 'instructions_screen.dart';
import 'result_history.dart';
import 'lab_submission_screen.dart';
import 'feedback_screen.dart';
import 'public_database_screen.dart';
import 'result_screen.dart';

import '../User/login_screen.dart';
import '../Chemical_expert/expert_schedule_screen.dart';
import 'expert_review_report_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _T {
  // Brand palette — deep navy + electric teal + warm amber accent
  static const navy = Color(0xFF0B1D2E);
  static const navyMid = Color(0xFF162D42);
  static const teal = Color(0xFF00BFA5);
  static const tealDim = Color(0xFF00897B);
  static const tealSurface = Color(0xFFE0F7F4);
  static const amber = Color(0xFFFFAB00);
  static const amberSurface = Color(0xFFFFF8E1);
  static const red = Color(0xFFD32F2F);
  static const redSurface = Color(0xFFFFEBEE);
  static const green = Color(0xFF2E7D32);
  static const greenSurface = Color(0xFFE8F5E9);

  static const bg = Color(0xFFF4F7F6);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFDFEDEB);
  static const divider = Color(0xFFEAF2F1);

  static const textPrimary = Color(0xFF0D2220);
  static const textSecondary = Color(0xFF4A7570);
  static const textHint = Color(0xFF90B5B0);

  static BoxDecoration card({double radius = 16, Color? color}) => BoxDecoration(
    color: color ?? cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: teal.withOpacity(0.055),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static const textTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const textBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static const textLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
}

// ─── Root screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: ValueListenableBuilder<List<TestResult>>(
          valueListenable: resultsStore,
          builder: (context, results, _) => _Body(results: results),
        ),
      ),
      floatingActionButton: _StartTestFab(
        onTap: () => _navigate(context, const StartTestScreen()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.cardBg,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.teal, _T.tealDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 9),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'GlowGuard',
                  style: TextStyle(
                    color: _T.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: ' AI',
                  style: TextStyle(
                    color: _T.teal,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _NotificationButton(),
        _LogoutButton(),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _T.border),
      ),
    );
  }
}

// ─── Scrollable body ──────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final List<TestResult> results;
  const _Body({required this.results});

  void _go(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        // ── Expert profile ─────────────────────────────────────────────────
        const _ExpertProfileHeader(),
        const SizedBox(height: 16),

        // ── Primary action card ────────────────────────────────────────────
        _PrimaryCard(
          onStart: () => _go(context, const StartTestScreen()),
          onInstructions: () => _go(context, const InstructionsScreen()),
        ),
        const SizedBox(height: 24),

        // ── Quick actions ──────────────────────────────────────────────────
        _SectionHeader(title: 'Quick Actions', badge: 'EXPERT'),
        const SizedBox(height: 12),
        _QuickActionsGrid(
          items: [
            _QItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Start Test',
              sub: 'Before/After photos',
              onTap: () => _go(context, const StartTestScreen()),
            ),
            _QItem(
              icon: Icons.menu_book_outlined,
              label: 'Instructions',
              sub: 'Step-by-step guide',
              onTap: () => _go(context, const InstructionsScreen()),
            ),
            _QItem(
              icon: Icons.history_rounded,
              label: 'History',
              sub: 'Saved results',
              onTap: () => _go(context, const HistoryScreen()),
            ),
            _QItem(
              icon: Icons.science_outlined,
              label: 'Lab Referral',
              sub: 'Submit for testing',
              onTap: () => _go(context, const LabSubmissionScreen()),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Safety insights ────────────────────────────────────────────────
        _SectionHeader(title: 'Safety Insights'),
        const SizedBox(height: 12),
        const _InsightsGrid(),
        const SizedBox(height: 24),

        // ── CTA cards ──────────────────────────────────────────────────────
        _CtaBanner(
          icon: Icons.feedback_outlined,
          title: 'Help improve GlowGuard',
          subtitle: 'Submit feedback about products or your experience.',
          buttonText: 'Give Feedback',
          color: _T.teal,
          onTap: () => _go(context, const FeedbackScreen()),
        ),
        const SizedBox(height: 10),
        _CtaBanner(
          icon: Icons.public_rounded,
          title: 'Browse public results',
          subtitle: 'Explore community-submitted chemical test results.',
          buttonText: 'Open Database',
          color: _T.tealDim,
          onTap: () => _go(context, const PublicDatabaseScreen()),
        ),
        const SizedBox(height: 24),

        // ── Latest results ─────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Latest Results',
                style: _T.textTitle.copyWith(fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _T.teal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (results.isEmpty)
          _EmptyResults()
        else
          ...results.take(3).map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ResultTile(
                result: r,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultScreen(result: r)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── App bar actions ──────────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dangerous_product_reports')
          .where('status', isEqualTo: 'Pending Review')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => _openAlertsSheet(context),
              icon: const Icon(Icons.notifications_outlined, color: _T.textPrimary),
              tooltip: 'Alerts',
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: _T.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logout',
      icon: const Icon(Icons.logout_rounded, color: _T.textSecondary),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      },
    );
  }
}

// ─── Expert profile header ────────────────────────────────────────────────────
class _ExpertProfileHeader extends StatelessWidget {
  const _ExpertProfileHeader();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _T.card(),
        child: const Text('Not logged in', style: _T.textBody),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('experts').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final callingName = data['callingName']?.toString() ?? 'Chemical Expert';
        final active = data['hasUpcomingAvailability'] == true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_T.navy, _T.navyMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _T.navy.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_T.teal, _T.tealDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.science_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      callingName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active ? _T.teal : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            active
                                ? 'Active · Available for appointments'
                                : 'Inactive · Set your availability',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? _T.teal : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Schedule button
              _CircleIconButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'Schedule',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpertScheduleScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Primary action card ──────────────────────────────────────────────────────
class _PrimaryCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onInstructions;
  const _PrimaryCard({required this.onStart, required this.onInstructions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.teal, _T.tealDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(0.30),
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
              // Icon box
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to test?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture before & after photos to analyse cosmetic product safety instantly.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
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
                child: _CardButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Start Test',
                  filled: true,
                  onTap: onStart,
                ),
              ),
              const SizedBox(width: 10),
              _CardButton(
                icon: Icons.menu_book_outlined,
                label: 'Guide',
                filled: false,
                onTap: onInstructions,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _CardButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: filled
              ? null
              : BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? _T.tealDim : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? _T.tealDim : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title, style: _T.textTitle),
        ),
        if (badge != null) _Badge(label: badge!),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _T.teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _T.teal.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: _T.textLabel.copyWith(color: _T.teal),
      ),
    );
  }
}

// ─── Quick actions grid ───────────────────────────────────────────────────────
class _QItem {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _QItem({required this.icon, required this.label, required this.sub, required this.onTap});
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QItem> items;
  const _QuickActionsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.62,
      ),
      itemBuilder: (_, i) => _QTile(item: items[i]),
    );
  }
}

class _QTile extends StatefulWidget {
  final _QItem item;
  const _QTile({required this.item});

  @override
  State<_QTile> createState() => _QTileState();
}

class _QTileState extends State<_QTile> {
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
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: _T.card(radius: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _T.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.item.icon, color: _T.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _T.textSecondary,
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

// ─── Safety insights grid ─────────────────────────────────────────────────────
class _InsightsGrid extends StatelessWidget {
  const _InsightsGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.lightbulb_outline_rounded, title: 'Lighting tip', value: 'Use daylight / white light'),
      (icon: Icons.camera_alt_outlined, title: 'Capture tip', value: 'Keep phone steady'),
      (icon: Icons.safety_check_outlined, title: 'Safety', value: 'Avoid skin contact'),
      (icon: Icons.info_outline_rounded, title: 'Note', value: 'Screening, not certification'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return _InsightCard(
          icon: item.icon,
          title: item.title,
          value: item.value,
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InsightCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _T.card(radius: 14, color: _T.tealSurface.withOpacity(0.55)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _T.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _T.teal, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _T.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA banner ───────────────────────────────────────────────────────────────
class _CtaBanner extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color color;
  final VoidCallback onTap;

  const _CtaBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CtaBanner> createState() => _CtaBannerState();
}

class _CtaBannerState extends State<_CtaBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _T.card(radius: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 14),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: _T.textTitle),
                    const SizedBox(height: 3),
                    Text(widget.subtitle, style: _T.textBody),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty results state ──────────────────────────────────────────────────────
class _EmptyResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: _T.card(radius: 16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _T.tealSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inbox_outlined, color: _T.teal, size: 24),
          ),
          const SizedBox(height: 12),
          const Text('No tests saved yet', style: _T.textTitle),
          const SizedBox(height: 5),
          const Text(
            'Start a test to see results here.',
            style: _T.textBody,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────
class _StartTestFab extends StatelessWidget {
  final VoidCallback onTap;
  const _StartTestFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: _T.teal,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text(
        'Start Test',
        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}

// ─── Alerts sheet launcher ───────────────────────────────────────────────────
void _openAlertsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: _T.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.60,
      maxChildSize: 0.92,
      minChildSize: 0.38,
      builder: (_, ctrl) => _AlertsList(scrollController: ctrl),
    ),
  );
}

class _AlertsList extends StatelessWidget {
  final ScrollController scrollController;
  const _AlertsList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dangerous_product_reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error: ${snap.error}', style: _T.textBody),
          );
        }

        final docs = snap.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _T.redSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_rounded, color: _T.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Product Hazard Reports',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _T.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _T.redSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${docs.length} reports',
                      style: _T.textLabel.copyWith(color: _T.red),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _T.border),
            const SizedBox(height: 4),

            if (docs.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No product hazard reports yet.',
                    style: TextStyle(color: _T.textHint, fontSize: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final product = data['productName'] ?? 'Unknown Product';
                    final brand = data['brand'] ?? 'Unknown Brand';
                    final status = data['status'] ?? 'Pending';
                    final isPending = status == 'Pending Review';

                    return _AlertCard(
                      product: product,
                      brand: brand,
                      status: status,
                      isPending: isPending,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpertReviewReportScreen(
                            reportId: doc.id,
                            reportData: data,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatefulWidget {
  final String product;
  final String brand;
  final String status;
  final bool isPending;
  final VoidCallback onTap;

  const _AlertCard({
    required this.product,
    required this.brand,
    required this.status,
    required this.isPending,
    required this.onTap,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPending ? _T.red : _T.green;
    final statusBg = widget.isPending ? _T.redSurface : _T.greenSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _T.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isPending ? _T.red.withOpacity(0.25) : _T.border,
              width: widget.isPending ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  widget.isPending
                      ? Icons.warning_rounded
                      : Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _T.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded, color: _T.textHint, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}