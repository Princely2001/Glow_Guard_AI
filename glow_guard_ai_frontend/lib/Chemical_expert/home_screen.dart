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

// ✅ Login screen
import '../User/login_screen.dart';

// ✅ schedule screen for experts
import '../Chemical_expert/expert_schedule_screen.dart';
import 'expert_review_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlowGuard AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // ✅ Notification Icon with Real-Time Badge for Pending Reports
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('dangerous_product_reports')
                .where('status', isEqualTo: 'Pending Review')
                .snapshots(),
            builder: (context, snapshot) {
              final hasAlerts = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              final alertCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => _openAlertsSheet(context),
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Alerts',
                  ),
                  if (hasAlerts)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          alertCount > 9 ? '9+' : alertCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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

                Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
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

                Text('Safety insights', style: Theme.of(context).textTheme.titleMedium),
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
                  subtitle: 'Explore community-submitted results.',
                  buttonText: 'Open database',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PublicDatabaseScreen()),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Text('Latest results', style: Theme.of(context).textTheme.titleMedium),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                          MaterialPageRoute(builder: (_) => ResultScreen(result: r)),
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

  // ✅ Show Bottom Sheet with List of Real-time Reports
  static void _openAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => _ReportAlertsList(scrollController: scrollController),
      ),
    );
  }
}

/// ✅ StreamBuilder Widget to fetch reports for the Alerts Sheet
class _ReportAlertsList extends StatelessWidget {
  final ScrollController scrollController;

  const _ReportAlertsList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Ordering by createdAt requires a Firestore index if combined with where().
      // To prevent crashes before you set up the index, we just fetch all and sort/filter locally,
      // or rely entirely on order (newest first).
      stream: FirebaseFirestore.instance
          .collection('dangerous_product_reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error fetching reports: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("No product hazard reports submitted yet.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final productName = data['productName'] ?? 'Unknown Product';
            final brandName = data['brand'] ?? 'Unknown Brand';
            final status = data['status'] ?? 'Pending';

            final isPending = status == 'Pending Review';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isPending ? Colors.red.shade200 : Colors.grey.shade300,
                  width: isPending ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isPending ? Colors.red.shade50 : Colors.grey.shade100,
                  child: Icon(
                    isPending ? Icons.warning_rounded : Icons.check_circle_outline,
                    color: isPending ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                ),
                title: Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brandName, style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                      ),
                    )
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // ✅ Navigates directly to the new dedicated Review Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpertReviewReportScreen(
                        reportId: doc.id,
                        reportData: data,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// ✅ Expert profile widget (reads callingName from experts/{uid})
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
      stream: FirebaseFirestore.instance.collection('experts').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final callingName = (data['callingName'] ?? 'Chemical Expert').toString();
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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