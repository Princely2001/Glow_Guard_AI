import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Import your new preview UI file
import 'credential_preview_sheet.dart';

class AdminExpertDetailsScreen extends StatefulWidget {
  final String expertId;
  final Map<String, dynamic> expertData;

  const AdminExpertDetailsScreen({
    super.key,
    required this.expertId,
    required this.expertData,
  });

  @override
  State<AdminExpertDetailsScreen> createState() => _AdminExpertDetailsScreenState();
}

class _AdminExpertDetailsScreenState extends State<AdminExpertDetailsScreen> {
  static const Color teal = Color(0xFF009688);

  bool _hasViewedDocument = false;
  bool _isSaving = false;

  String _displayOrNA(dynamic v) {
    final s = (v ?? "").toString().trim();
    return s.isEmpty ? "N/A" : s;
  }

  bool _isHttpUrl(String? url) {
    if (url == null) return false;
    final u = Uri.tryParse(url);
    if (u == null) return false;
    return u.scheme == "http" || u.scheme == "https";
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('experts').doc(widget.expertId).update({
        'status': status,
        if (status == 'active') 'approvedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == "active" ? "Expert approved ✅" : "Expert rejected ❌"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expert = widget.expertData;

    final name = _displayOrNA(expert['callingName']);
    final email = _displayOrNA(expert['email']);
    final qualification = _displayOrNA(expert['educationLevel']);
    final experience = _displayOrNA(expert['chemicalTestingExperienceYears']);
    final contact = _displayOrNA(expert['contactNumber']);
    final docUrl = expert['credentialUrl']?.toString();

    // ✅ Added Government Registration ID extraction
    final govRegId = _displayOrNA(expert['govRegistrationId']);

    final hasDoc = _isHttpUrl(docUrl);
    final canApprove = !hasDoc || _hasViewedDocument;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Review Application"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _HeaderCard(name: name, email: email),
          const SizedBox(height: 12),

          _SectionCard(
            title: "Applicant details",
            child: Column(
              children: [
                _InfoRow(label: "Qualification", value: qualification),
                _InfoRow(label: "Experience", value: "$experience years"),
                _InfoRow(label: "Contact", value: contact),
                // ✅ Display the Government Registration ID
                _InfoRow(label: "Gov. Reg. ID", value: govRegId),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: "Professional credentials",
            trailing: hasDoc
                ? _StatusPill(
              text: _hasViewedDocument ? "REVIEWED" : "NOT REVIEWED",
              color: _hasViewedDocument ? Colors.green : const Color(0xFFF59E0B),
            )
                : const _StatusPill(text: "MISSING", color: Colors.red),
            child: hasDoc
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await CredentialPreviewSheet.show(
                      context,
                      url: docUrl!,
                      onViewed: () {
                        setState(() => _hasViewedDocument = true);
                      },
                    );
                  },
                  icon: Icon(
                    _hasViewedDocument
                        ? Icons.check_circle_outline
                        : Icons.visibility_outlined,
                  ),
                  label: Text(_hasViewedDocument ? "View again" : "View document"),
                  style: FilledButton.styleFrom(
                    foregroundColor: teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tip: Approve is enabled after you view the document.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            )
                : const Text(
              "No credential document link provided.",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        hasDoc: hasDoc,
        hasViewed: _hasViewedDocument,
        onReject: () => _updateStatus('rejected'),
        onApprove: canApprove ? () => _updateStatus('active') : null,
      ),
    );
  }
}

/* ---------------- UI pieces ---------------- */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.email});

  final String name;
  final String email;

  static const Color teal = Color(0xFF009688);

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: teal.withOpacity(0.12),
            child: Text(
              initial,
              style: const TextStyle(color: teal, fontWeight: FontWeight.w900),
            ),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _StatusPill(text: "PENDING", color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.hasDoc,
    required this.hasViewed,
    required this.onReject,
    required this.onApprove,
  });

  final bool hasDoc;
  final bool hasViewed;
  final VoidCallback onReject;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7E9F0))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDoc && !hasViewed)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please view the document before approving.",
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text("Reject"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.withOpacity(0.35),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}