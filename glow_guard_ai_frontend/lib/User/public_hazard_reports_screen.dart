import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicHazardReportsScreen extends StatelessWidget {
  const PublicHazardReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text("Verified Hazard Database", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "These products have been reviewed by chemical experts and confirmed to pose health risks based on user evidence.",
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dangerous_product_reports')
                  .where('status', isEqualTo: 'Reviewed')
                  .where('isApprovedForPublic', isEqualTo: true)
              // .orderBy('reviewedAt', descending: true) // Requires Firestore index
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "No verified hazard reports are currently publicly available.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.science_rounded, color: Colors.red.shade700),
                        ),
                        title: Text(
                          data['productName'] ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          data['brand'] ?? 'Unknown Brand',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded, color: Colors.grey),
                        onTap: () => _showFullReportDialog(context, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Show Full Report in a Popup Dialog
  void _showFullReportDialog(BuildContext context, Map<String, dynamic> data) {
    final timelines = List<Map<String, dynamic>>.from(data['timelineExperiences'] ?? []);

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['productName'] ?? 'Unknown Product',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                data['brand'] ?? 'Unknown Brand',
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  // Dialog Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Expert Opinion Section
                          Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.teal.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text("Official Expert Opinion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade900)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              data['expertOpinion'] ?? 'No additional comments provided by the expert.',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),

                          const Divider(height: 40),

                          // User Timeline Evidence Section
                          const Text("User Evidence Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),

                          if (timelines.isEmpty)
                            const Text("No timeline data provided.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            ...timelines.map((entry) {
                              final severity = (entry['severity'] as num?)?.toDouble() ?? 1.0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry['stage'] ?? 'Unknown Stage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                          Text(
                                            "Severity: ${severity.toInt()}/5",
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: severity >= 4 ? Colors.red.shade800 : Colors.orange.shade800),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(entry['sideEffectsDescription'] ?? 'No description provided.', style: const TextStyle(fontSize: 14)),

                                          if (entry['evidenceImageUrl'] != null) ...[
                                            const SizedBox(height: 12),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                entry['evidenceImageUrl'],
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  height: 120,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                                                ),
                                              ),
                                            )
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  // Dialog Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                        ]
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close Report"),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }
}