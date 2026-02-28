import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _idC = TextEditingController();
  bool _loading = false;
  String? _error;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  static const String _collection = 'chemical test private';

  @override
  void dispose() {
    _idC.dispose();
    super.dispose();
  }

  // ✅ Legacy normalize
  String _normalizeLegacyId(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  bool _looksLikeLegacyFormat(String input) {
    return RegExp(r'[^A-Za-z0-9]').hasMatch(input);
  }

  Future<Map<String, dynamic>?> _findByDocId(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    data['__docId'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> _findByRecordId(String recordId) async {
    final q = await _db
        .collection(_collection)
        .where('recordId', isEqualTo: recordId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    final data = d.data();
    data['__docId'] = d.id;
    return data;
  }

  Future<void> _search() async {
    final raw = _idC.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final candidates = <String>[raw];
      if (_looksLikeLegacyFormat(raw)) {
        candidates.add(_normalizeLegacyId(raw));
      }

      Map<String, dynamic>? foundData;

      for (final candidate in candidates) {
        foundData = await _findByDocId(candidate);
        if (foundData != null) break;

        foundData = await _findByRecordId(candidate);
        if (foundData != null) break;
      }

      setState(() => _loading = false);

      if (foundData != null) {
        _idC.clear();
        _showReportSheet(foundData);
      } else {
        setState(() => _error = "No report found for ID: $raw");
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Search error: $e";
      });
    }
  }

  void _showReportSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        _ResultReportCard(data: data),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text("My Lab Results", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // 🔎 SEARCH SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Manual Search", style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idC,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            if (!_loading) _search();
                          },
                          decoration: InputDecoration(
                            hintText: "Paste Record ID",
                            hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: cs.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loading ? null : _search,
                          child: _loading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text("Find"),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 📩 MESSAGES / INBOX HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Recent Results",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 📬 MESSAGES LIST (REAL-TIME STREAM)
          Expanded(
            child: _currentUserId == null
                ? const Center(child: Text("Please log in to see your results."))
                : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection(_collection)
                  .where('requestedUserId', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                var docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState(cs);
                }

                // Sort in memory to avoid needing a Firestore Composite Index
                final sortedDocs = docs.toList()..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime); // Descending
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = sortedDocs[index].data() as Map<String, dynamic>;
                    return _MessageTile(
                      data: data,
                      onTap: () => _showReportSheet(data),
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

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_email_read_outlined, size: 48, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text("No results yet", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "When an expert completes your test,\nthe result will appear here automatically.",
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ MESSAGE TILE (Inbox Style Item)
// ---------------------------------------------------------------------------
class _MessageTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _MessageTile({required this.data, required this.onTap});

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return "${d.month}/${d.day}/${d.year} at $hh:$mm";
    }
    return "Recently";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labelRaw = (data['predictionLabel'] ?? data['label'] ?? '').toString();
    final isSafe = labelRaw.toLowerCase() == 'safe';
    final testType = (data['testType'] ?? 'Unknown Test').toString();
    final date = _formatDate(data['createdAt'] ?? data['requestedDateTime']);

    // Styling based on outcome
    final iconColor = isSafe ? Colors.green : Colors.redAccent;
    final iconData = isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded;
    final bgColor = isSafe ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Icon
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lab Result Ready",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        date,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Test Type: $testType",
                    style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Outcome: ${labelRaw.isEmpty ? 'Unclear' : labelRaw.toUpperCase()}",
                    style: TextStyle(
                      color: isSafe ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tap to view the full detailed report and images.",
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// ✅ FULL REPORT CARD (Untouched data logic from your previous version)
// ---------------------------------------------------------------------------
class _ResultReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultReportCard({required this.data});

  String _s(dynamic v) => (v ?? '').toString().trim();

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatDate(dynamic requestedDateTime, dynamic createdAt, String createdAtLocal) {
    Timestamp? pickTs(dynamic v) => v is Timestamp ? v : null;

    final ts = pickTs(requestedDateTime) ?? pickTs(createdAt);
    if (ts != null) {
      final d = ts.toDate();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} $hh:$mm";
    }
    if (createdAtLocal.isNotEmpty) {
      return createdAtLocal.replaceFirst('T', ' ').split('.').first;
    }
    return "Unknown";
  }

  String _findUrl(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().startsWith('http')) return v.trim();
    }
    final images = data['images'];
    if (images is Map) {
      for (final k in keys) {
        final short = k
            .replaceAll('ImageUrl', '')
            .replaceAll('Url', '')
            .toLowerCase();
        final v = images[short];
        if (v is String && v.trim().startsWith('http')) return v.trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final recordId = _s(data['recordId']).isNotEmpty ? _s(data['recordId']) : _s(data['__docId']);
    final testType = _s(data['testType']);
    final label = _s(data['predictionLabel']).isNotEmpty ? _s(data['predictionLabel']) : _s(data['label']);
    final outcomeRaw = _s(data['outcome']);
    final expertEmail = _s(data['expertEmail']).isNotEmpty ? _s(data['expertEmail']) : "Unknown Expert";

    final confPercentStored = _toInt(data['confidencePercent']);
    final confidenceRaw = _toDouble(data['confidence']);
    final confPercent = confPercentStored > 0
        ? confPercentStored
        : (confidenceRaw <= 1.0 ? (confidenceRaw * 100).round() : confidenceRaw.round()).clamp(0, 100);

    final labelLower = label.toLowerCase();
    final outcome = outcomeRaw.isNotEmpty
        ? outcomeRaw
        : (labelLower.isEmpty ? 'unclear' : (labelLower == 'safe' ? 'notDetected' : 'detected'));

    final probsRaw = data['probs'];
    final probs = (probsRaw is List) ? probsRaw : const [];
    double toProb(dynamic v) {
      final d = _toDouble(v);
      return d > 1.0 ? (d / 100.0) : d;
    }

    final safeProb = probs.isNotEmpty ? toProb(probs.elementAt(0)) : 0.0;
    final hqProb = probs.length > 1 ? toProb(probs[1]) : 0.0;
    final hgProb = probs.length > 2 ? toProb(probs[2]) : 0.0;
    final stProb = probs.length > 3 ? toProb(probs[3]) : 0.0;

    final isSafe = labelLower == 'safe';
    final isUnclear = outcome.toLowerCase().contains('unclear');

    final mergedUrl = _findUrl(['mergedImageUrl', 'mergedUrl', 'merged', 'combinedImageUrl', 'previewUrl']);
    final beforeUrl = _findUrl(['beforeImageUrl', 'beforeUrl', 'before']);
    final afterUrl = _findUrl(['afterImageUrl', 'afterUrl', 'after']);

    final createdAtLocal = _s(data['createdAtLocal']);
    final createdAt = data['createdAt'];
    final requestedDateTime = data['requestedDateTime'];
    final dateTimeStr = _formatDate(requestedDateTime, createdAt, createdAtLocal);

    final badgeText = isUnclear ? "UNCLEAR" : (isSafe ? "SAFE" : "DANGER");
    final badgeBg = isUnclear
        ? cs.secondaryContainer
        : (isSafe ? cs.primaryContainer : cs.errorContainer);
    final badgeFg = isUnclear
        ? cs.onSecondaryContainer
        : (isSafe ? cs.primary : cs.error);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "FULL REPORT",
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontWeight: FontWeight.w900, color: badgeFg),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          Text(
            label.isEmpty ? "Unknown" : label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: isUnclear ? cs.secondary : (isSafe ? cs.primary : cs.error),
            ),
          ),

          const SizedBox(height: 6),

          _kvRow("Outcome", outcome),
          _kvRow("Confidence", "$confPercent%"),
          _kvRow("Test Type", testType.isEmpty ? "-" : testType),
          _kvRow("Test Time", dateTimeStr),
          _kvRow("Tested by", expertEmail),
          _kvRow("Record ID", recordId.isEmpty ? "-" : recordId),

          const Divider(height: 26),

          if (probs.isNotEmpty) ...[
            Text("Probability Breakdown", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            _probLine(context, "Safe", safeProb, isGood: true),
            _probLine(context, "Hydroquinone", hqProb),
            _probLine(context, "Mercury", hgProb),
            _probLine(context, "Steroids", stProb),
            const Divider(height: 26),
          ],

          Text("Evidence Photos", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),

          if (mergedUrl.isNotEmpty) ...[
            _NetImageCard(url: mergedUrl, tag: "Combined (Before + After)"),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(child: _NetImageCard(url: beforeUrl, tag: "Before")),
              const SizedBox(width: 10),
              Expanded(child: _NetImageCard(url: afterUrl, tag: "After")),
            ],
          ),

          const SizedBox(height: 14),
          Text(
            "Tip: If you need help understanding this report, contact your chemical expert.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              v.isEmpty ? "-" : v,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _probLine(BuildContext context, String name, double v, {bool isGood = false}) {
    final cs = Theme.of(context).colorScheme;
    final pct = (v * 100).clamp(0, 100).toStringAsFixed(1);

    final strong = v >= 0.55;
    final barColor = isGood
        ? (strong ? cs.primary : cs.onSurfaceVariant)
        : (strong ? cs.error : cs.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w600),
                ),
              ),
              Text(
                "$pct%",
                style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: cs.outlineVariant.withOpacity(0.35),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ NETWORK IMAGE WITH ZOOM (Untouched)
// ---------------------------------------------------------------------------
class _NetImageCard extends StatelessWidget {
  final String url;
  final String tag;

  const _NetImageCard({required this.url, required this.tag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (url.trim().isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
          color: cs.surfaceContainerHighest.withOpacity(0.55),
        ),
        child: Text("No image", style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, p) {
                  if (p == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black45,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                tag,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}