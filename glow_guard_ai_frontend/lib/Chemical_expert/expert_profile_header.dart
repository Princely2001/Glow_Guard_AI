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

// ✅ Login screen (change path if needed)
import '../User/login_screen.dart';

// ✅ schedule screen for experts (change path if needed)
import '../Chemical_expert/expert_schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlowGuard AI'),
        actions: [
          IconButton(
            onPressed: () => _openAlertsSheet(context),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Alerts',
          ),

          // ✅ LOGOUT: sign out + go to login
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),

          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<TestResult>>(
          valueListenable: resultsStore,
          builder: (context, results, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ✅ Expert profile header (fixed overflow)
                const _ExpertProfileHeader(),
                const SizedBox(height: 14),

                PrimaryActionCard(
                  onStart: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StartTestScreen()),
                  ),
                  onInstructions: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InstructionsScreen()),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Quick actions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),

                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  children: [
                    QuickActionTile(
                      title: 'Start Test',
                      subtitle: 'Before/After photos',
                      icon: Icons.qr_code_scanner,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StartTestScreen()),
                      ),
                    ),
                    QuickActionTile(
                      title: 'Instructions',
                      subtitle: 'Step-by-step guide',
                      icon: Icons.menu_book_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InstructionsScreen()),
                      ),
                    ),
                    QuickActionTile(
                      title: 'History',
                      subtitle: 'Saved results',
                      icon: Icons.history,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    QuickActionTile(
                      title: 'Lab Referral',
                      subtitle: 'Submit for testing',
                      icon: Icons.science_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LabSubmissionScreen()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text('Safety insights',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: InsightChip(
                        icon: Icons.lightbulb_outline,
                        title: 'Lighting tip',
                        value: 'Use daylight / white light',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InsightChip(
                        icon: Icons.camera_alt_outlined,
                        title: 'Capture tip',
                        value: 'Keep phone steady',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: InsightChip(
                        icon: Icons.safety_check_outlined,
                        title: 'Safety',
                        value: 'Avoid skin contact',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InsightChip(
                        icon: Icons.info_outline,
                        title: 'Note',
                        value: 'Screening, not certification',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                CtaCard(
                  title: 'Help improve GlowGuard',
                  subtitle: 'Submit feedback about products or your experience.',
                  buttonText: 'Give feedback',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                CtaCard(
                  title: 'Browse public results',
                  subtitle: 'Explore community-submitted results (design-only).',
                  buttonText: 'Open database',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PublicDatabaseScreen()),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Text('Latest results',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (results.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inbox_outlined, color: cs.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No tests saved yet. Start a test to see results here.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...results.take(3).map(
                        (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ResultTile(
                        result: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(result: r),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StartTestScreen()),
        ),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Start Test'),
      ),
    );
  }

  static void _openAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alerts (Design Only)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text('• New guidance when results are Detected/Unclear'),
              Text('• Reminders to capture photos in stable lighting'),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ Expert profile widget (reads callingName from experts/{uid})
/// ✅ FIXED: no overflow on small screens
class _ExpertProfileHeader extends StatelessWidget {
  const _ExpertProfileHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: const Text("Not logged in"),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
      FirebaseFirestore.instance.collection('experts').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final callingName = (data['callingName'] ?? 'Chemical Expert').toString();

        // optional: you can compute active from your schedule collection later
        final active = (data['hasUpcomingAvailability'] ?? false) == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer.withOpacity(0.85),
                cs.surfaceContainerHighest.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primary,
                child: Icon(Icons.science_outlined, color: cs.onPrimary),
              ),
              const SizedBox(width: 12),

              // ✅ EXPANDED prevents overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      callingName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ status pill (ellipsis)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.green.withOpacity(0.12)
                            : cs.surfaceContainerHighest.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? Colors.green : cs.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: active ? Colors.green : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              active
                                  ? "Active • available for appointments"
                                  : "Inactive • set your availability",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ✅ FIX: use compact icon button (no text -> no overflow)
              IconButton.filledTonal(
                tooltip: "Schedule",
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpertScheduleScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
