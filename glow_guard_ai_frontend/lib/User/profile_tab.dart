import 'package:flutter/material.dart';

// ✅ Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'View_Test_Results.dart';
import '../User/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text("Profile not found in database."));
          }

          final data = snap.data!.data() ?? {};
          final name = (data['name'] ?? 'User').toString();
          final email = (data['email'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final gender = (data['gender'] ?? '').toString();
          final dob = (data['dob'] ?? '').toString();
          final education = (data['education'] ?? '').toString();
          final cosmeticExp = (data['cosmeticExp'] ?? '').toString();
          final chemicalExp = (data['chemicalExp'] ?? '').toString();
          final userId = (data['userId'] ?? '').toString();
          final photoUrl = (data['photoUrl'] ?? '').toString();

          return CustomScrollView(
            slivers: [
              // ✅ Modern Header (SliverAppBar)
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: cs.primary,
                elevation: 0,
                title: const Text("Profile"),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.tertiary,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _ModernAvatar(photoUrl: photoUrl),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email.isEmpty ? "User account" : email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (userId.isNotEmpty)
                                        _Pill(
                                          text: userId,
                                          bg: Colors.white.withOpacity(0.18),
                                          border: Colors.white.withOpacity(0.30),
                                          fg: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryActionButton(
                              icon: Icons.receipt_long_outlined,
                              label: "My Requests",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TonalActionButton(
                              icon: Icons.settings_outlined,
                              label: "Settings",
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Settings (design only).")),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Text("Your Details", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),

                      // ✅ Modern Details Card
                      _SectionCard(
                        child: Column(
                          children: [
                            _DetailRow(icon: Icons.phone_outlined, title: "Phone", value: phone),
                            const SizedBox(height: 10),
                            _DetailRow(icon: Icons.wc_outlined, title: "Gender", value: gender),
                            const SizedBox(height: 10),
                            _DetailRow(icon: Icons.cake_outlined, title: "Date of Birth", value: dob),
                            const SizedBox(height: 10),
                            _DetailRow(icon: Icons.school_outlined, title: "Education", value: education),
                            const SizedBox(height: 10),
                            _DetailRow(icon: Icons.brush_outlined, title: "Cosmetic Experience", value: cosmeticExp),
                            const SizedBox(height: 10),
                            _DetailRow(icon: Icons.science_outlined, title: "Chemical Experience", value: chemicalExp),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ Logout Modern Button
                      _DangerButton(
                        label: "Logout",
                        subtitle: "Return to login screen",
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ---------------- UI WIDGETS ----------------

class _ModernAvatar extends StatelessWidget {
  final String photoUrl;
  const _ModernAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.18),
          )
        ],
      ),
      child: CircleAvatar(
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? const Icon(Icons.person, size: 30, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  final Color fg;

  const _Pill({
    required this.text,
    required this.bg,
    required this.border,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withOpacity(0.18)),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value.isEmpty ? "-" : value,
            textAlign: TextAlign.right,
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: cs.primary.withOpacity(0.22),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _TonalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TonalActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.error.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: cs.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: cs.onErrorContainer.withOpacity(0.85))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onErrorContainer),
          ],
        ),
      ),
    );
  }
}
