import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/test_models.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Your existing collection name
  static const String _collection = 'chemical test private';

  DateTimeRange? _range;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------
  // Query builder
  // ----------------------------
  Query<Map<String, dynamic>> _buildQuery() {
    final expert = _auth.currentUser;

    if (expert == null) {
      return _db.collection(_collection).where('expertId', isEqualTo: '__none__');
    }

    Query<Map<String, dynamic>> q =
    _db.collection(_collection).where('expertId', isEqualTo: expert.uid);

    // Optional date range filter (start inclusive, end exclusive)
    if (_range != null) {
      final start = Timestamp.fromDate(_startOfDay(_range!.start));
      final endExclusive = Timestamp.fromDate(_endExclusive(_range!.end));
      q = q
          .where('requestedDateTime', isGreaterThanOrEqualTo: start)
          .where('requestedDateTime', isLessThan: endExclusive);
    }

    // Sort newest first
    return q.orderBy('requestedDateTime', descending: true);
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _endExclusive(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.add(const Duration(days: 1));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime d) {
    final date = _fmtDate(d);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$date  $hh:$mm';
  }

  String _rangeLabel(DateTimeRange r) => '${_fmtDate(r.start)} → ${_fmtDate(r.end)}';

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );

    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  void _clearRange() => setState(() => _range = null);

  void _quickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _range = DateTimeRange(start: now.subtract(Duration(days: days)), end: now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expert = _auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: expert == null
            ? const Center(
          child: Text('Please log in as a chemical expert to view history.'),
        )
            : CustomScrollView(
          slivers: [
            // ✅ Modern header
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              backgroundColor: cs.surface,
              elevation: 0,
              title: const Text('History'),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withOpacity(0.10),
                        cs.secondary.withOpacity(0.08),
                        cs.tertiary.withOpacity(0.06),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Your completed chemical tests',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(
                      controller: _searchController,
                      hintText: 'Search by Record ID…',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickRange,
                          icon: const Icon(Icons.date_range),
                          label: const Text('Search by date'),
                        ),
                        if (_range != null)
                          OutlinedButton.icon(
                            onPressed: _clearRange,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        _QuickChip(label: 'Last 7 days', onTap: () => _quickRange(7)),
                        _QuickChip(label: 'Last 30 days', onTap: () => _quickRange(30)),
                        _QuickChip(label: 'Today', onTap: () => _quickRange(0)),
                      ],
                    ),
                    if (_range != null) ...[
                      const SizedBox(height: 10),
                      _FilterPill(text: 'Filtered: ${_rangeLabel(_range!)}'),
                    ],
                  ],
                ),
              ),
            ),

            // ✅ Results list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _buildQuery().snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _EmptyState(
                        title: 'Something went wrong',
                        subtitle: 'Error: ${snap.error}',
                        icon: Icons.error_outline,
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 28),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const _EmptyState(
                        title: 'No history yet',
                        subtitle: 'Your completed tests will appear here.',
                        icon: Icons.history,
                      );
                    }

                    // ✅ Build items containing BOTH:
                    // - TestResult (for tile summary)
                    // - raw Firestore map (for FULL REPORT)
                    final allItems = docs.map((d) {
                      final r = _docToTestResult(d);
                      final raw = Map<String, dynamic>.from(d.data() ?? {});
                      raw['__docId'] = d.id;
                      raw['recordId'] = (raw['recordId'] ?? d.id).toString();
                      return _HistoryItem(result: r, raw: raw);
                    }).toList();

                    // Local search by recordId (no extra Firestore query)
                    var items = allItems;
                    if (_searchText.isNotEmpty) {
                      final s = _searchText.toLowerCase();
                      items = items
                          .where((it) => it.result.id.toLowerCase().contains(s))
                          .toList();
                    }

                    if (items.isEmpty) {
                      return const _EmptyState(
                        title: 'No matches',
                        subtitle: 'Try a different Record ID or clear filters.',
                        icon: Icons.search_off,
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Text(
                                '${items.length} record(s)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final r = item.result;
                            final raw = item.raw;

                            return _ModernHistoryCard(
                              result: r,
                              dateText: _fmtDateTime(r.time),
                              onCopyId: () async {
                                await Clipboard.setData(ClipboardData(text: r.id));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Record ID copied')),
                                );
                              },
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(
                                    result: r,
                                    reportData: raw, // ✅ FULL REPORT DATA
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // Firestore -> TestResult
  // ----------------------------
  TestResult _docToTestResult(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final id = (data['recordId'] ?? doc.id).toString();

    final ts = data['requestedDateTime'];
    final time = (ts is Timestamp) ? ts.toDate() : DateTime.now();

    final typeStr = (data['testType'] ?? '').toString().trim();
    final type = TestType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
      orElse: () => TestType.mercury,
    );

    final confidence = _toConfidenceInt(data['confidence']);
    final note = (data['note'] ?? '').toString();

    final beforePath = _firstNonEmptyString([
      data['beforeImageUrl'],
      data['beforeImagePath'],
    ]);

    final afterPath = _firstNonEmptyString([
      data['afterImageUrl'],
      data['afterImagePath'],
    ]);

    final label = (data['predictionLabel'] ?? '').toString().trim();
    final outcome = _deriveOutcome(label);

    return TestResult(
      id: id,
      time: time,
      type: type,
      outcome: outcome,
      confidence: confidence,
      note: note,
      beforePath: beforePath,
      afterPath: afterPath,
    );
  }

  int _toConfidenceInt(dynamic value) {
    if (value is int) return value.clamp(0, 100);

    if (value is double) {
      if (value >= 0.0 && value <= 1.0) return (value * 100).round().clamp(0, 100);
      return value.round().clamp(0, 100);
    }

    if (value is num) {
      final v = value.toDouble();
      if (v >= 0.0 && v <= 1.0) return (v * 100).round().clamp(0, 100);
      return v.round().clamp(0, 100);
    }

    return 0;
  }

  String? _firstNonEmptyString(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  TestOutcome _deriveOutcome(String label) {
    final l = label.toLowerCase();

    if (l == 'safe' || l == 'no harmful chemical detected') {
      return TestOutcome.notDetected;
    }

    if (l.contains('mercury') || l.contains('hydroquinone') || l.contains('steroids')) {
      return TestOutcome.detected;
    }

    return TestOutcome.unclear;
  }
}

// ----------------------------
// Helper item class (avoid Dart record syntax issues)
// ----------------------------
class _HistoryItem {
  final TestResult result;
  final Map<String, dynamic> raw;
  const _HistoryItem({required this.result, required this.raw});
}

// ----------------------------
// Modern UI widgets
// ----------------------------
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary.withOpacity(0.55)),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}

class _FilterPill extends StatelessWidget {
  final String text;
  const _FilterPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onPrimaryContainer.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ModernHistoryCard extends StatelessWidget {
  final TestResult result;
  final String dateText;
  final VoidCallback onTap;
  final VoidCallback onCopyId;

  const _ModernHistoryCard({
    required this.result,
    required this.dateText,
    required this.onTap,
    required this.onCopyId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (badgeBg, badgeFg, badgeIcon) = switch (result.outcome) {
      TestOutcome.notDetected => (cs.tertiaryContainer, cs.onTertiaryContainer, Icons.verified_outlined),
      TestOutcome.detected => (cs.errorContainer, cs.onErrorContainer, Icons.warning_amber_rounded),
      TestOutcome.unclear => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.help_outline),
    };

    final confidence = result.confidence.clamp(0, 100);
    final confValue = confidence / 100.0;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: badgeFg.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 16, color: badgeFg),
                        const SizedBox(width: 6),
                        Text(
                          outcomeTitle(result.outcome),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Record ID: ${result.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy Record ID',
                    onPressed: onCopyId,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                'Test: ${testTypeLabel(result.type)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: confValue,
                        minHeight: 8,
                        backgroundColor: cs.surfaceVariant.withOpacity(0.45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$confidence%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              if (result.note.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  result.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.70),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    'Tap to view full results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.60),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.55)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 34, color: cs.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
