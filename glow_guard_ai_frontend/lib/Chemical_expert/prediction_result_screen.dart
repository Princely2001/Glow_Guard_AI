import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/test_models.dart';
import '../services/Chemical_expert/ml/ingredient_classifier.dart';

class PredictionResultScreen extends StatefulWidget {
  final MlPrediction prediction;
  final TestType testType;
  final File before;
  final File after;
  final Uint8List? mergedPreviewPng;

  // ✅ CALLBACK: Returns recordId when saved
  final Future<String> Function()? onSaveToDatabase;

  // optional
  final Future<void> Function()? onSendToRequester;

  const PredictionResultScreen({
    super.key,
    required this.prediction,
    required this.testType,
    required this.before,
    required this.after,
    required this.mergedPreviewPng,
    this.onSendToRequester,
    this.onSaveToDatabase,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scale;

  bool _sending = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _scale = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  bool get _isSafe => widget.prediction.label.toLowerCase().trim() == 'safe';

  String _prettyProbs(MlPrediction p) {
    final probs = p.probs.map((v) => (v * 100).toStringAsFixed(1)).toList();
    if (probs.length == 4) {
      return 'Safe ${probs[0]}% • HQ ${probs[1]}% • Hg ${probs[2]}% • Steroids ${probs[3]}%';
    }
    return probs.join(' • ');
  }

  String _testTypeName(TestType t) => t.toString().split('.').last;

  Future<void> _handleSend() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      if (widget.onSendToRequester != null) {
        await widget.onSendToRequester!.call();
      } else {
        await Future.delayed(const Duration(milliseconds: 900));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results sent to requester successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send results: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ✅ SAVE HANDLER
  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      String recordId = "";
      if (widget.onSaveToDatabase != null) {
        // Calls the service function passed from TestScreen
        recordId = await widget.onSaveToDatabase!.call();
      } else {
        await Future.delayed(const Duration(milliseconds: 900));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recordId.isEmpty ? 'Test result saved.' : 'Saved ✅ Record ID: $recordId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save result: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conf = widget.prediction.confidence.clamp(0.0, 1.0);

    final statusTitle = _isSafe ? 'Looks Safe' : 'Danger Detected';
    final statusSubtitle = _isSafe
        ? 'No harmful ingredient strongly detected by the model.'
        : 'A harmful ingredient pattern was detected. Please avoid use and consult guidance.';

    final headerBg = _isSafe ? cs.primaryContainer : cs.errorContainer;
    final headerFg = _isSafe ? cs.primary : cs.error;
    final accent = _isSafe ? cs.primary : cs.error;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Prediction Result'),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slideUp,
          child: ScaleTransition(
            scale: _scale,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ... Header and Confidence UI ...
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _isSafe ? cs.outlineVariant : cs.error.withOpacity(0.45)),
                    color: cs.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: headerBg, borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              widget.prediction.label,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: headerFg, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outlineVariant)),
                            child: Text(
                              _testTypeName(widget.testType).toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(_isSafe ? Icons.verified_rounded : Icons.warning_rounded, color: accent, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(statusTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(statusSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: conf),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Confidence', style: Theme.of(context).textTheme.titleMedium),
                                  const Spacer(),
                                  Text('${(value * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(value: value, minHeight: 12, backgroundColor: cs.outlineVariant.withOpacity(0.55), valueColor: AlwaysStoppedAnimation<Color>(accent)),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(_prettyProbs(widget.prediction), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text('Combined image used for prediction', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _MergedPreviewCard(bytes: widget.mergedPreviewPng),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _ThumbCard(title: 'Before', file: widget.before)),
                    const SizedBox(width: 12),
                    Expanded(child: _ThumbCard(title: 'After', file: widget.after)),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _handleSend,
                        icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                        label: Text(_sending ? 'Sending...' : 'Send to Requester'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _handleSave,
                        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save to Database'),
                      ),
                    ),
                  ],
                ),

                // ... Back buttons ...
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Run another test'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ... _MergedPreviewCard and _ThumbCard classes remain the same ...
class _MergedPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  const _MergedPreviewCard({required this.bytes});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
        color: cs.surfaceContainerHighest,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            bytes == null ? const Center(child: CircularProgressIndicator()) : Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            const Positioned(left: 12, top: 12, child: _Pill(text: 'Before')),
            const Positioned(right: 12, top: 12, child: _Pill(text: 'After')),
          ],
        ),
      ),
    );
  }
}

class _ThumbCard extends StatelessWidget {
  final String title;
  final File file;
  const _ThumbCard({required this.title, required this.file});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outlineVariant), color: cs.surfaceContainerHighest),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Positioned(left: 10, top: 10, child: _Pill(text: title)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}