import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final apptRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Details")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: apptRef.snapshots(),
        builder: (context, apptSnap) {
          if (apptSnap.hasError) {
            return _errorBox(cs, "Error loading appointment:\n${apptSnap.error}");
          }
          if (apptSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!apptSnap.hasData || !apptSnap.data!.exists) {
            return _infoBox(cs, "Appointment not found.");
          }

          final appt = apptSnap.data!.data() ?? {};
          final expertId = (appt['expertId'] ?? '').toString();

          final dateId = (appt['dateId'] ?? '').toString();
          final slot = (appt['slot'] ?? '').toString();
          final status = (appt['status'] ?? '').toString();

          final expertName = (appt['expertName'] ?? '').toString();
          final expertSpecialty = (appt['expertSpecialty'] ?? '').toString();
          final expertPhotoUrl = (appt['expertPhotoUrl'] ?? '').toString();

          if (expertId.isEmpty) {
            return _errorBox(cs, "Expert ID missing in appointment.");
          }

          final expertRef = FirebaseFirestore.instance.collection('experts').doc(expertId);

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: expertRef.snapshots(),
            builder: (context, expertSnap) {
              if (expertSnap.hasError) {
                return _errorBox(cs, "Error loading expert:\n${expertSnap.error}");
              }
              if (expertSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final expert = expertSnap.data?.data() ?? {};

              // ✅ Correct fields (based on your expert register backend)
              final email = (expert['email'] ?? '').toString();

              // You stored phone as "contactNumber"
              final phone = (expert['contactNumber'] ?? expert['phone'] ?? '').toString();

              // Optional: show callingName if you saved it
              final callingName = (expert['callingName'] ?? '').toString();

              final displayExpertName = callingName.isNotEmpty
                  ? callingName
                  : (expertName.isEmpty ? "Chemical Expert" : expertName);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(0.06),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.primary,
                          backgroundImage: expertPhotoUrl.isNotEmpty ? NetworkImage(expertPhotoUrl) : null,
                          child: expertPhotoUrl.isEmpty
                              ? const Icon(Icons.science_outlined, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayExpertName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expertSpecialty.isEmpty ? "Expert" : expertSpecialty,
                                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text("Appointment", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _tile(cs, Icons.calendar_today_outlined, "Date", dateId.isEmpty ? "-" : dateId),
                  _tile(cs, Icons.access_time_outlined, "Time", slot.isEmpty ? "-" : slot),
                  _tile(cs, Icons.verified_outlined, "Status", status.isEmpty ? "-" : status),

                  const SizedBox(height: 16),

                  // ✅ New: IMPORTANT sample sending instructions
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text(
                              "Important",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please contact the chemical expert using the email or phone number below and send your cosmetics cream sample before the appointment.",
                          style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "On the sample packaging, clearly write:\n• Your name\n• Appointment date: ${dateId.isEmpty ? '-' : dateId}\n• Appointment time: ${slot.isEmpty ? '-' : slot}",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text("Expert Contact", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _tile(cs, Icons.email_outlined, "Email", email.isEmpty ? "Not provided" : email),
                  _tile(cs, Icons.phone_outlined, "Phone", phone.isEmpty ? "Not provided" : phone),

                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(ColorScheme cs, IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withOpacity(0.20)),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(ColorScheme cs, String msg) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
      ),
    );
  }

  Widget _errorBox(ColorScheme cs, String msg) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(msg, style: TextStyle(color: cs.onErrorContainer)),
      ),
    );
  }
}
