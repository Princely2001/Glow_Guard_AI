import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart'; // Assuming you have ModernCard or similar here

class ExpertReviewReportScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ExpertReviewReportScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<ExpertReviewReportScreen> createState() => _ExpertReviewReportScreenState();
}

class _ExpertReviewReportScreenState extends State<ExpertReviewReportScreen> {
  final TextEditingController _expertOpinionController = TextEditingController();
  bool _approveForPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _expertOpinionController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_expertOpinionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide an expert opinion or analysis.", style: TextStyle(color: Colors.white))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Update the document in Firestore
      await FirebaseFirestore.instance
          .collection('dangerous_product_reports')
          .doc(widget.reportId)
          .update({
        'status': 'Reviewed',
        'expertOpinion': _expertOpinionController.text.trim(),
        'isApprovedForPublic': _approveForPublic,
        'reviewedByExpertId': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Show Success and Pop
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to Home Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting review: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = widget.reportData;
    final timelines = List<Map<String, dynamic>>.from(data['timelineExperiences'] ?? []);
    final bool isAnonymous = data['isAnonymous'] ?? true;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text("Perform Safety Review", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: Product Identity ---
            Text("Product Under Investigation", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Product Name", data['productName'] ?? 'Unknown'),
                    const Divider(),
                    _buildInfoRow("Brand / Manufacturer", data['brand'] ?? 'Unknown'),
                    const Divider(),
                    _buildInfoRow("Reported By", isAnonymous ? "Anonymous User" : (data['reportedByUserId'] ?? 'Unknown')),
                    const Divider(),
                    _buildInfoRow("Date Submitted", data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION 2: User Evidence & Timeline ---
            Text("User Evidence & Timeline", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Review the documented side effects and attached photographic evidence.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),

            if (timelines.isEmpty)
              const Text("No timeline data provided.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              ...timelines.map((entry) => _buildTimelineCard(entry, cs)),

            const SizedBox(height: 32),

            // --- SECTION 3: Expert Conclusion (Actionable) ---
            Text("Official Expert Review", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.teal.shade200, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science_rounded, color: Colors.teal.shade800),
                        const SizedBox(width: 8),
                        Text("Chemical / Medical Analysis", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expertOpinionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Enter your scientific evaluation. What hazardous ingredients might be causing this? e.g., 'The severe hyperpigmentation suggests the presence of unlisted Hydroquinone...'",
                        hintStyle: TextStyle(color: Colors.teal.shade300, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Public Approval Toggle ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade100)
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.teal.shade700,
                        title: const Text("Approve for Public Database", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Warning: Ensure no Personally Identifiable Information (PII) is visible in the photos before approving.", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        value: _approveForPublic,
                        onChanged: (val) => setState(() => _approveForPublic = val),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submitReview,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Finalize & Update Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> entry, ColorScheme cs) {
    final severity = (entry['severity'] as num?)?.toDouble() ?? 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [
            BoxShadow(color: Colors.orange.shade100.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry['stage'] ?? 'Unknown Stage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severity >= 4 ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Severity: ${severity.toInt()}/5",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: severity >= 4 ? Colors.red.shade800 : Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reported Symptoms:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(entry['sideEffectsDescription'] ?? 'No description provided.', style: const TextStyle(fontSize: 14)),

                if (entry['evidenceImageUrl'] != null) ...[
                  const SizedBox(height: 16),
                  const Text("Photographic Evidence:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      entry['evidenceImageUrl'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
                      ),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}