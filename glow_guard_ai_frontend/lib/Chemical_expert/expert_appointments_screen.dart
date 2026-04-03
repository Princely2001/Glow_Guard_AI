import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'test_screen.dart';

class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() =>
      _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState extends State<ExpertAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isCompleted(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final chemicalStatus =
    (data['chemicalStatus'] ?? '').toString().trim().toLowerCase();
    final testStatus =
    (data['testStatus'] ?? '').toString().trim().toLowerCase();

    return status == 'completed' ||
        status == 'done' ||
        status == 'test_completed' ||
        chemicalStatus == 'completed' ||
        chemicalStatus == 'done' ||
        testStatus == 'completed' ||
        testStatus == 'done' ||
        data['chemicalTestDone'] == true ||
        data['resultSaved'] == true;
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected';
  }

  bool _isBooked(Map<String, dynamic> data) {
    return !_isCompleted(data) && !_isCancelled(data);
  }

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser?.uid;

    if (expertId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Appointments")),
        body: const Center(child: Text("Not logged in.")),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('appointments')
        .where('expertId', isEqualTo: expertId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointments"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snap.data?.docs ?? const [],
              );

              final bookedCount =
                  docs.where((d) => _isBooked(d.data())).length;
              final completedCount =
                  docs.where((d) => _isCompleted(d.data())).length;
              final cancelledCount =
                  docs.where((d) => _isCancelled(d.data())).length;

              return TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Booked ($bookedCount)'),
                  Tab(text: 'Completed ($completedCount)'),
                  Tab(text: 'Cancelled ($cancelledCount)'),
                ],
              );
            },
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snap.data?.docs ?? const [],
          );

          docs.sort((a, b) {
            final ad = a.data();
            final bd = b.data();
            final at = (ad['date'] is Timestamp)
                ? (ad['date'] as Timestamp).millisecondsSinceEpoch
                : 0;
            final bt = (bd['date'] is Timestamp)
                ? (bd['date'] as Timestamp).millisecondsSinceEpoch
                : 0;
            return at.compareTo(bt);
          });

          final bookedDocs = docs.where((d) => _isBooked(d.data())).toList();
          final completedDocs =
          docs.where((d) => _isCompleted(d.data())).toList();
          final cancelledDocs =
          docs.where((d) => _isCancelled(d.data())).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _AppointmentsList(
                docs: bookedDocs,
                emptyText: "No booked appointments yet.",
              ),
              _AppointmentsList(
                docs: completedDocs,
                emptyText: "No completed appointments yet.",
              ),
              _AppointmentsList(
                docs: cancelledDocs,
                emptyText: "No cancelled appointments yet.",
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String emptyText;

  const _AppointmentsList({
    required this.docs,
    required this.emptyText,
  });

  bool _isCompleted(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final chemicalStatus =
    (data['chemicalStatus'] ?? '').toString().trim().toLowerCase();
    final testStatus =
    (data['testStatus'] ?? '').toString().trim().toLowerCase();

    return status == 'completed' ||
        status == 'done' ||
        status == 'test_completed' ||
        chemicalStatus == 'completed' ||
        chemicalStatus == 'done' ||
        testStatus == 'completed' ||
        testStatus == 'done' ||
        data['chemicalTestDone'] == true ||
        data['resultSaved'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (docs.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = docs[i];
        final data = d.data();

        final userId = (data['userId'] ?? '').toString();
        final dateId = (data['dateId'] ?? '').toString();
        final slot = (data['slot'] ?? '').toString();
        final status = (data['status'] ?? 'booked').toString();

        final isCompleted = _isCompleted(data);

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data() ?? {};
            final userName = (userData['name'] ?? 'User').toString();
            final userEmail = (userData['email'] ?? '').toString();
            final userPhone = (userData['phone'] ?? '').toString();

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpertAppointmentDetailsScreen(
                      appointmentId: d.id,
                      appointmentData: data,
                      userName: userName,
                      userEmail: userEmail,
                      userPhone: userPhone,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: (isCompleted ? Colors.green : cs.primary)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isCompleted ? Colors.green : cs.primary)
                              .withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.event_available,
                        color: isCompleted ? Colors.green : cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (dateId.isEmpty || slot.isEmpty)
                                ? "Appointment"
                                : "$dateId • $slot",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userSnap.connectionState == ConnectionState.waiting
                                ? "Loading user..."
                                : userName,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail.isEmpty ? "No email" : userEmail,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusChip(status: isCompleted ? "completed" : status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ExpertAppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final String userName;
  final String userEmail;
  final String userPhone;

  const ExpertAppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  State<ExpertAppointmentDetailsScreen> createState() =>
      _ExpertAppointmentDetailsScreenState();
}

class _ExpertAppointmentDetailsScreenState
    extends State<ExpertAppointmentDetailsScreen> {
  bool _busy = false;
  String? _error;

  bool get _isCompleted {
    final status =
    (widget.appointmentData['status'] ?? '').toString().trim().toLowerCase();
    return status == 'completed' ||
        status == 'done' ||
        status == 'test_completed' ||
        widget.appointmentData['chemicalTestDone'] == true ||
        widget.appointmentData['resultSaved'] == true;
  }

  Future<void> _goToStartTestScreen() async {
    if (_busy || _isCompleted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final requestedUserId =
      (widget.appointmentData['userId'] ?? '').toString();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StartTestScreen(
            requestedUserId: requestedUserId,
            appointmentId: widget.appointmentId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = "Failed to open test screen: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateId = (widget.appointmentData['dateId'] ?? '').toString();
    final slot = (widget.appointmentData['slot'] ?? '').toString();
    final status = _isCompleted
        ? 'completed'
        : (widget.appointmentData['status'] ?? 'booked').toString();
    final specialty =
    (widget.appointmentData['expertSpecialty'] ?? '').toString();

    DateTime? date;
    if (widget.appointmentData['date'] is Timestamp) {
      date = (widget.appointmentData['date'] as Timestamp).toDate();
    }

    final dateText = (date != null)
        ? DateFormat("EEE, MMM d, yyyy").format(date)
        : (dateId.isEmpty ? "-" : dateId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withOpacity(0.95),
                  cs.secondaryContainer.withOpacity(0.75),
                  cs.tertiaryContainer.withOpacity(0.60),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$dateText • $slot",
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: cs.onPrimaryContainer.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Status: $status",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (specialty.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 18,
                        color: cs.onPrimaryContainer.withOpacity(0.85),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Specialty: $specialty",
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                            cs.onPrimaryContainer.withOpacity(0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: "User Contact",
            icon: Icons.person_outline,
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.badge_outlined,
                  label: "Name",
                  value: widget.userName.isEmpty ? "-" : widget.userName,
                ),
                const SizedBox(height: 10),
                DetailRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: widget.userEmail.isEmpty ? "-" : widget.userEmail,
                  trailing: widget.userEmail.isEmpty
                      ? null
                      : IconButton.filledTonal(
                    tooltip: "Copy email",
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.userEmail),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email copied")),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: "Chemical Test",
            icon: Icons.science_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: (_busy || _isCompleted) ? null : _goToStartTestScreen,
                  icon: _busy
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    _isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.biotech_rounded,
                  ),
                  label: Text(
                    _isCompleted
                        ? "Chemical Test Completed"
                        : (_busy ? "Opening..." : "Do Chemical Test"),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 6),
                Text(
                  _isCompleted
                      ? "This appointment has already been completed and saved."
                      : "This will open the test screen to upload before/after images, run the AI model, then show the result page.",
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.8)),
          ),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = status.trim().toLowerCase();

    Color bg;
    Color fg;
    IconData icon;

    if (s == 'completed' || s == 'done' || s == 'test_completed') {
      bg = Colors.green.withOpacity(0.14);
      fg = Colors.green.shade700;
      icon = Icons.check_circle_outline;
    } else if (s == 'accepted' || s == 'confirmed' || s == 'booked') {
      bg = cs.tertiaryContainer;
      fg = cs.onTertiaryContainer;
      icon = Icons.verified_outlined;
    } else if (s == 'pending') {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
      icon = Icons.hourglass_bottom_rounded;
    } else if (s == 'rejected' || s == 'cancelled' || s == 'canceled') {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
      icon = Icons.cancel_outlined;
    } else {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: fg,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}