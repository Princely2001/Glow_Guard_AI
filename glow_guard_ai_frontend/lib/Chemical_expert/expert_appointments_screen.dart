import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ExpertAppointmentsScreen extends StatelessWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      appBar: AppBar(title: const Text("Appointments")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ Make modifiable list to sort
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snap.data?.docs ?? const [],
          );

          // ✅ Sort locally (no Firestore index needed)
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

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No appointments yet.",
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

              final isBooked = status == "booked";

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
                              color: (isBooked ? cs.primary : cs.outlineVariant).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isBooked ? cs.primary : cs.outlineVariant).withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              isBooked ? Icons.event_available : Icons.event_busy,
                              color: isBooked ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (dateId.isEmpty || slot.isEmpty) ? "Appointment" : "$dateId • $slot",
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userSnap.connectionState == ConnectionState.waiting ? "Loading user..." : userName,
                                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isBooked ? cs.primary : cs.onSurfaceVariant).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: (isBooked ? cs.primary : cs.onSurfaceVariant).withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isBooked ? cs.primary : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// ✅ Details screen: shows appointment + user contact
class ExpertAppointmentDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateId = (appointmentData['dateId'] ?? '').toString();
    final slot = (appointmentData['slot'] ?? '').toString();
    final status = (appointmentData['status'] ?? 'booked').toString();
    final specialty = (appointmentData['expertSpecialty'] ?? '').toString();

    DateTime? date;
    if (appointmentData['date'] is Timestamp) {
      date = (appointmentData['date'] as Timestamp).toDate();
    }

    final dateText = (date != null)
        ? DateFormat("EEE, MMM d, yyyy").format(date!)
        : (dateId.isEmpty ? "-" : dateId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // ✅ Colorful Header Card
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    Icon(Icons.info_outline, size: 18, color: cs.onPrimaryContainer.withOpacity(0.85)),
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
                      Icon(Icons.science_outlined, size: 18, color: cs.onPrimaryContainer.withOpacity(0.85)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Specialty: $specialty",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.9),
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

          // ✅ Contact Section Card (more modern surface)
          SectionCard(
            title: "User Contact",
            icon: Icons.person_outline,
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.badge_outlined,
                  label: "Name",
                  value: userName.isEmpty ? "-" : userName,
                ),
                const SizedBox(height: 10),
                DetailRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: userEmail.isEmpty ? "-" : userEmail,
                  trailing: userEmail.isEmpty
                      ? null
                      : IconButton.filledTonal(
                    tooltip: "Copy email",
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: userEmail));
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

          const SizedBox(height: 12),

          // ✅ Tip Card (tinted, not boring grey)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                  ),
                  child: Icon(Icons.lightbulb_outline, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Use the email/phone to confirm test details with the user.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSecondaryContainer.withOpacity(0.95),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _detailTile(ColorScheme cs, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
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

    if (s == 'accepted' || s == 'confirmed') {
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
