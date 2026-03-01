import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_expert_details_screen.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  static const Color teal = Color(0xFF009688);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Pending Verifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('experts')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: "Couldn’t load applications",
              subtitle: "${snapshot.error}",
              accent: Colors.red,
              actionText: "Try again",
              onAction: () => (context as Element).markNeedsBuild(),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _StateMessage(
              icon: Icons.inbox_outlined,
              title: "No pending verifications",
              subtitle: "New expert applications will appear here.",
              accent: teal,
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final expert = doc.data() as Map<String, dynamic>;
              final expertId = doc.id;

              final name = (expert['callingName'] ?? "Unknown").toString();
              final email = (expert['email'] ?? "").toString();
              final degree = (expert['educationLevel'] ?? "N/A").toString();
              final expYears = (expert['chemicalTestingExperienceYears'] ?? 0).toString();

              return _ModernExpertCard(
                name: name,
                email: email,
                degree: degree,
                expYears: expYears,
                onReview: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminExpertDetailsScreen(
                        expertId: expertId,
                        expertData: expert,
                      ),
                    ),
                  );
                },
                theme: theme,
              );
            },
          );
        },
      ),
    );
  }
}

class _ModernExpertCard extends StatelessWidget {
  const _ModernExpertCard({
    required this.name,
    required this.email,
    required this.degree,
    required this.expYears,
    required this.onReview,
    required this.theme,
  });

  final String name;
  final String email;
  final String degree;
  final String expYears;
  final VoidCallback onReview;
  final ThemeData theme;

  static const Color teal = AdminVerificationScreen.teal;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onReview,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E9F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: teal.withOpacity(0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    text: "PENDING",
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Info chips row
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.school_outlined,
                    label: degree,
                  ),
                  _InfoChip(
                    icon: Icons.timeline_outlined,
                    label: "$expYears yrs",
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text("Review Application"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF374151)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7E9F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent.withOpacity(0.12),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onAction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(actionText!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}