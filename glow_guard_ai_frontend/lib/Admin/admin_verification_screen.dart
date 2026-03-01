import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  Future<void> _updateExpertStatus(BuildContext context, String uid, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('experts').doc(uid).update({
        'status': newStatus,
        if (newStatus == 'active') 'approvedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Expert status updated to $newStatus.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF009688);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin: Pending Verifications"),
        backgroundColor: teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('experts')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending expert verifications."));
          }

          final pendingExperts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingExperts.length,
            itemBuilder: (context, index) {
              final expert = pendingExperts[index].data() as Map<String, dynamic>;
              final expertId = pendingExperts[index].id;
              final credentialUrl = expert['credentialUrl'] as String?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert['callingName'] ?? "Unknown",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Email: ${expert['email']}"),
                      Text("Degree: ${expert['educationLevel']}"),
                      Text("Experience: ${expert['chemicalTestingExperienceYears']} years"),
                      const SizedBox(height: 12),

                      if (credentialUrl != null)
                        OutlinedButton.icon(
                          onPressed: () => _launchUrl(credentialUrl),
                          icon: const Icon(Icons.remove_red_eye),
                          label: const Text("View Credential Document"),
                        )
                      else
                        const Text("No document uploaded.", style: TextStyle(color: Colors.red)),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateExpertStatus(context, expertId, 'rejected'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Reject"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateExpertStatus(context, expertId, 'active'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text("Approve"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}