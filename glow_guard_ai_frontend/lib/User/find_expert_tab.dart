import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_appointment_screen.dart';

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

    final expertsQuery = FirebaseFirestore.instance
        .collection('experts')
        .where('hasUpcomingAvailability', isEqualTo: true);

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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: expertsQuery.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData) {
                    return const Center(child: Text("No experts found."));
                  }

                  final docs = snap.data!.docs;

                  final filtered = docs.where((d) {
                    final data = d.data();
                    final name = (data['callingName'] ?? data['name'] ?? 'Expert').toString();
                    final specialty = (data['specialty'] ?? 'Chemical Expert').toString();
                    final s = "$name $specialty".toLowerCase();
                    return _q.isEmpty || s.contains(_q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No matching experts.",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      final data = d.data();

                      final expertId = d.id;
                      final name = (data['callingName'] ?? data['name'] ?? 'Expert').toString();
                      final specialty = (data['specialty'] ?? 'Chemical Expert').toString();
                      final photoUrl = (data['photoUrl'] ?? '').toString();
                      final rating = (data['rating'] ?? 4.8).toString();
                      final jobs = (data['jobs'] ?? 0).toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentScreen(
                              expertId: expertId,
                              expertName: name,
                              expertSpecialty: specialty,
                              expertPhotoUrl: photoUrl,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                                color: Colors.black.withOpacity(0.05),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: cs.primaryContainer,
                                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                child: photoUrl.isEmpty
                                    ? Icon(Icons.science_outlined, color: cs.onPrimaryContainer)
                                    : null,
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
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$specialty • ⭐ $rating • $jobs jobs",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.circle, size: 10, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Active (available)",
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookAppointmentScreen(
                                      expertId: expertId,
                                      expertName: name,
                                      expertSpecialty: specialty,
                                      expertPhotoUrl: photoUrl,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text("Book"),
                              ),
                            ],
                          ),
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
