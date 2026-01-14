import 'package:flutter/material.dart';
import 'user_store.dart';
import 'request_test_screen.dart';

class FindExpertTab extends StatefulWidget {
  const FindExpertTab({super.key});

  @override
  State<FindExpertTab> createState() => _FindExpertTabState();
}

class _FindExpertTabState extends State<FindExpertTab> {
  String _q = "";

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Find Chemical Expert")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search by name or specialty...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: expertsStore,
                builder: (context, List<Expert> experts, _) {
                  final filtered = experts.where((e) {
                    final s = "${e.name} ${e.specialty}".toLowerCase();
                    return _q.isEmpty || s.contains(_q);
                  }).toList();

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.person, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${e.specialty} • ⭐ ${e.rating} • ${e.jobs} jobs",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RequestTestScreen(expert: e)),
                              ),
                              child: const Text("Request"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
