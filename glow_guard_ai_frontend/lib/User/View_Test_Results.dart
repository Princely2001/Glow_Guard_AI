import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _idC = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _searchResult;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String _collection = 'chemical test private';

  @override
  void dispose() {
    _idC.dispose();
    super.dispose();
  }

  // ✅ Legacy normalize only (for inputs like: 2026/01/17 11AM -> 2026011711AM)
  // IMPORTANT: Do NOT apply this to auto Firestore ids (they are case-sensitive)
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
    data['__docId'] = doc.id; // keep doc id for fallback
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

    setState(() {
      _loading = true;
      _error = null;
      _searchResult = null;
    });

    if (raw.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Please enter a valid Test Result ID.";
      });
      return;
    }

    try {
      // Search candidates: raw first (exact), then recordId raw,
      // then if legacy-like, also try normalized version.
      final candidates = <String>[raw];
      if (_looksLikeLegacyFormat(raw)) {
        candidates.add(_normalizeLegacyId(raw));
      }

      for (final candidate in candidates) {
        // 1) exact docId (case-sensitive)
        final byDoc = await _findByDocId(candidate);
        if (byDoc != null) {
          setState(() {
            _loading = false;
            _searchResult = byDoc;
          });
          return;
        }

        // 2) recordId field
        final byRecord = await _findByRecordId(candidate);
        if (byRecord != null) {
          setState(() {
            _loading = false;
            _searchResult = byRecord;
          });
          return;
        }
      }

      setState(() {
        _loading = false;
        _error = "No report found for ID: $raw";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Search error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("My Chemical Tests")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔎 SEARCH BY ID
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Search by Test Result ID",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  "Enter the ID given by the chemical expert.\n"
                      "Supports BOTH:\n"
                      "• New unique IDs (paste exactly)\n"
                      "• Legacy format (example: 2026/01/17 11AM) — auto-fixed",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _idC,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (!_loading) _search();
                  },
                  decoration: InputDecoration(
                    hintText: "Paste Record ID here",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _search,
                    child: Text(_loading ? "Searching..." : "Find Report"),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                ],

                if (_searchResult != null) ...[
                  const SizedBox(height: 16),
                  _ResultReportCard(data: _searchResult!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ FULL REPORT CARD (Outcome + Confidence + Images)
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

  // Prefer requestedDateTime (your test time), fallback createdAt
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

    // recordId fallback to docId
    final recordId = _s(data['recordId']).isNotEmpty ? _s(data['recordId']) : _s(data['__docId']);

    final testType = _s(data['testType']);
    final label = _s(data['predictionLabel']).isNotEmpty ? _s(data['predictionLabel']) : _s(data['label']);
    final outcomeRaw = _s(data['outcome']);
    final expertEmail = _s(data['expertEmail']).isNotEmpty ? _s(data['expertEmail']) : "Unknown Expert";

    // confidence supports:
    // - confidencePercent
    // - confidence as 0..1
    // - confidence as 0..100
    final confPercentStored = _toInt(data['confidencePercent']);
    final confidenceRaw = _toDouble(data['confidence']);
    final confPercent = confPercentStored > 0
        ? confPercentStored
        : (confidenceRaw <= 1.0 ? (confidenceRaw * 100).round() : confidenceRaw.round()).clamp(0, 100);

    // outcome fallback
    final labelLower = label.toLowerCase();
    final outcome = outcomeRaw.isNotEmpty
        ? outcomeRaw
        : (labelLower.isEmpty ? 'unclear' : (labelLower == 'safe' ? 'notDetected' : 'detected'));

    // probs (optional)
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

    // image urls
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
// ✅ NETWORK IMAGE WITH ZOOM
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
