import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/Chemical_expert/chemical_test_private_service.dart';

class LabSubmissionScreen extends StatelessWidget {
  const LabSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ChemicalTestPrivateService _service = ChemicalTestPrivateService();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Lab Requests Board'),
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchAllProfessionalRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading requests: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, size: 64, color: cs.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No professional lab requests found.', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              // Extract fields with fallbacks
              final testType = data['testType'] ?? 'Unknown';
              final label = data['predictionLabel'] ?? 'N/A';
              final note = data['expertNote'] ?? 'No notes provided.';
              final status = data['status'] ?? 'pending_lab_review';
              final expertEmail = data['requestingExpertEmail'] ?? 'Unknown Expert';
              final dateStr = data['requestedDateTime'];
              final beforeImg = data['beforeImageUrl'];
              final afterImg = data['afterImageUrl'];

              // Format date simply
              String displayDate = '';
              if (dateStr != null) {
                try {
                  final dt = DateTime.parse(dateStr).toLocal();
                  displayDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {}
              }

              // Status UI colors
              final isPending = status == 'pending_lab_review';
              final statusColor = isPending ? cs.errorContainer : cs.tertiaryContainer;
              final statusTextColor = isPending ? cs.onErrorContainer : cs.onTertiaryContainer;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: Images ---
                    if (beforeImg != null && afterImg != null)
                      SizedBox(
                        height: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(beforeImg, fit: BoxFit.cover),
                                  Positioned(left: 8, top: 8, child: _ImageLabel(text: 'Before')),
                                ],
                              ),
                            ),
                            Container(width: 2, color: cs.surface),
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(afterImg, fit: BoxFit.cover),
                                  Positioned(right: 8, top: 8, child: _ImageLabel(text: 'After')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- Body: Details ---
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$testType TEST'.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: cs.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toString().replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(expertEmail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (displayDate.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: cs.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(displayDate, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),

                          Divider(height: 24, color: cs.outlineVariant),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.memory_rounded, size: 18, color: cs.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'AI Prediction: $label',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded, size: 18, color: cs.onSurface),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    note,
                                    style: Theme.of(context).textTheme.bodyMedium
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ImageLabel extends StatelessWidget {
  final String text;
  const _ImageLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}