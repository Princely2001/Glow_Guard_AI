import 'package:flutter/material.dart';
import 'my_requests_screen.dart';
import '../User/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        "User account (design only)",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: cs.surfaceContainerHighest,
            title: const Text("My Requests"),
            subtitle: const Text("Track status and view results"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
          const SizedBox(height: 10),

          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: cs.surfaceContainerHighest,
            title: const Text("Settings"),
            subtitle: const Text("Notifications, privacy, theme"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Settings (design only).")),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ LOGOUT (navigation only)
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: cs.errorContainer,
            title: Text(
              "Logout",
              style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              "Return to login screen",
              style: TextStyle(color: cs.onErrorContainer.withOpacity(0.85)),
            ),
            trailing: Icon(Icons.logout, color: cs.onErrorContainer),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
