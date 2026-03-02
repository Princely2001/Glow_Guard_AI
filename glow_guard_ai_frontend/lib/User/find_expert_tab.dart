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
  String _selectedDistrict = "All Districts";

  // List of all Sri Lankan districts plus an "All Districts" option for clearing the filter
  final _sriLankanDistricts = const [
    "All Districts",
    "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo",
    "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara",
    "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar",
    "Matale", "Matara", "Moneragala", "Mullaitivu", "Nuwara Eliya",
    "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
  ];

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
            // Search by Name or Specialty
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
            const SizedBox(height: 12),

            // Filter by Location (District)
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              items: _sriLankanDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDistrict = v!),
              decoration: InputDecoration(
                labelText: "Filter by Location",
                prefixIcon: const Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
                    final name = (data['callingName'] ?? data['name'] ?? 'Expert').toString().toLowerCase();
                    final specialty = (data['specialty'] ?? 'Chemical Expert').toString().toLowerCase();
                    final location = (data['location'] ?? '').toString();

                    // Match text query
                    final matchesSearch = _q.isEmpty || name.contains(_q) || specialty.contains(_q);

                    // Match location dropdown
                    final matchesDistrict = _selectedDistrict == "All Districts" || location == _selectedDistrict;

                    return matchesSearch && matchesDistrict;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No matching experts found for the selected location.",
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
                      final location = (data['location'] ?? 'Location not set').toString();
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
                                    // Display location alongside specialty and rating
                                    Text(
                                      "$specialty • 📍 $location\n⭐ $rating • $jobs jobs",
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