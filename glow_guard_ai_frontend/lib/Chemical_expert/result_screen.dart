import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/test_models.dart';
import '../widgets/common_widgets.dart';

import 'home_screen.dart';
import 'instructions_screen.dart';
import 'lab_submission_screen.dart';

class ResultScreen extends StatelessWidget {
  final TestResult result;

  /// ✅ Pass the Firestore document data when coming from History
  /// so we can show the full report (probs, expertEmail, images, etc.)
  final Map<String, dynamic>? reportData;

  const ResultScreen({
    super.key,
    required this.result,
    this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg) = switch (result.outcome) {
      TestOutcome.notDetected => (cs.tertiaryContainer, cs.onTertiaryContainer),
      TestOutcome.detected => (cs.errorContainer, cs.onErrorContainer),
      TestOutcome.unclear => (cs.secondaryContainer, cs.onSecondaryContainer),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Summary card (your original)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: fg.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcomeTitle(result.outcome),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: fg),
                ),
                const SizedBox(height: 6),
                Text(
                  'Test: ${testTypeLabel(result.type)} • Confidence: ${result.confidence}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: fg.withOpacity(0.9)),
                ),
                const SizedBox(height: 10),
                Text(
                  result.note.trim().isEmpty ? 'No note added.' : result.note,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: fg.withOpacity(0.95)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ FULL REPORT (only if we have Firestore data)
          if (reportData != null) ...[
            _FullReportCard(
              data: reportData!,
              fallback: result, // fallback to TestResult if fields missing
            ),
            const SizedBox(height: 14),
          ],

          // ✅ Next steps (your original)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next steps', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                const Bullet(text: 'Retake photos in stable lighting if unclear.'),
                const Bullet(text: 'Use a plain background for better contrast.'),
                const Bullet(text: 'If Detected/Unclear, consider lab confirmation.'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        ),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Instructions',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InstructionsScreen()),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (result.outcome != TestOutcome.notDetected)
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LabSubmissionScreen()),
              ),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Submit to Lab (Design Only)'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ FULL REPORT CARD (same idea as your MyRequests full report)
// ---------------------------------------------------------------------------
class _FullReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final TestResult fallback;

  const _FullReportCard({
    required this.data,
    required this.fallback,
  });

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

    final recordId = _s(data['recordId']).isNotEmpty ? _s(data['recordId']) : fallback.id;

    final testType = _s(data['testType']).isNotEmpty
        ? _s(data['testType'])
        : testTypeLabel(fallback.type);

    final label = _s(data['predictionLabel']).isNotEmpty ? _s(data['predictionLabel']) : _s(data['label']);

    final expertEmail = _s(data['expertEmail']).isNotEmpty ? _s(data['expertEmail']) : "Unknown Expert";

    // confidence: supports confidencePercent, or confidence 0..1 or 0..100
    final confPercentStored = _toInt(data['confidencePercent']);
    final confidenceRaw = _toDouble(data['confidence']);
    final confPercent = confPercentStored > 0
        ? confPercentStored
        : (confidenceRaw == 0
        ? fallback.confidence
        : (confidenceRaw <= 1.0 ? (confidenceRaw * 100).round() : confidenceRaw.round()))
        .clamp(0, 100);

    // outcome fallback
    final outcomeRaw = _s(data['outcome']);
    final labelLower = (label.isNotEmpty ? label : outcomeTitle(fallback.outcome)).toLowerCase();
    final outcome = outcomeRaw.isNotEmpty
        ? outcomeRaw
        : (fallback.outcome == TestOutcome.unclear
        ? 'unclear'
        : (fallback.outcome == TestOutcome.notDetected ? 'notDetected' : 'detected'));

    final isSafe = (labelLower == 'safe') || (fallback.outcome == TestOutcome.notDetected);
    final isUnclear = outcome.toLowerCase().contains('unclear') || fallback.outcome == TestOutcome.unclear;

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

    // images
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
            label.isEmpty ? outcomeTitle(fallback.outcome) : label,
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
          _kvRow("Record ID", recordId),

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
