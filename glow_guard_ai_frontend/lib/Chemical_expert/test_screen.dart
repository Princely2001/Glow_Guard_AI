import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/test_models.dart';
import '../models/results_store.dart';
import '../widgets/common_widgets.dart';
import '../Chemical_expert/instructions_screen.dart';

// ✅ ML & Service Imports
import '../services/Chemical_expert/ml/ingredient_classifier.dart';
import '../Chemical_expert/prediction_result_screen.dart';
import '../services/Chemical_expert/chemical_test_private_service.dart';

class StartTestScreen extends StatefulWidget {
  final String? requestedUserId;
  final String? appointmentId;

  const StartTestScreen({
    super.key,
    this.requestedUserId,
    this.appointmentId,
  });

  @override
  State<StartTestScreen> createState() => _StartTestScreenState();
}

class _StartTestScreenState extends State<StartTestScreen> {
  final _picker = ImagePicker();

  final ChemicalTestPrivateService _storageService = ChemicalTestPrivateService();

  TestType _type = TestType.mercury;
  File? _before;
  File? _after;

  bool _busy = false;
  final IngredientClassifier _clf = IngredientClassifier();
  bool _modelReady = false;
  MlPrediction? _lastPrediction;

  Uint8List? _mergedPreviewPng;
  int _mergeJob = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _clf.load(threads: 2);
      if (!mounted) return;
      setState(() => _modelReady = true);
    } catch (e) {
      debugPrint('Model load failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model load failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _clf.dispose();
    super.dispose();
  }

  Future<void> _pickBefore(ImageSource src) async {
    final x = await _picker.pickImage(source: src);
    if (x == null) return;
    setState(() => _before = File(x.path));
    await _updateMergedPreview();
  }

  Future<void> _pickAfter(ImageSource src) async {
    final x = await _picker.pickImage(source: src);
    if (x == null) return;
    setState(() => _after = File(x.path));
    await _updateMergedPreview();
  }

  Future<void> _updateMergedPreview() async {
    if (_before == null || _after == null) return;
    final job = ++_mergeJob;
    try {
      final bytes = await _clf.buildMergedPreviewPng(before: _before!, after: _after!);
      if (!mounted || job != _mergeJob) return;
      setState(() => _mergedPreviewPng = bytes);
    } catch (e) {
      debugPrint('Preview merge failed: $e');
    }
  }

  String _testTypeLabel(TestType t) => t.toString().split('.').last.toUpperCase();

  String _prettyProbs(MlPrediction p) {
    final probs = p.probs.map((v) => (v * 100).toStringAsFixed(1)).toList();
    if (probs.length == 4) {
      return 'Safe ${probs[0]}% | HQ ${probs[1]}% | Hg ${probs[2]}% | Steroids ${probs[3]}%';
    }
    return probs.join(' , ');
  }

  Future<void> _analyze() async {
    if (_before == null || _after == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add BOTH Before and After photos.')),
      );
      return;
    }

    if (!_modelReady || !_clf.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ML model is not ready.')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _lastPrediction = null;
    });

    try {
      final pred = await _clf.predictMergedBeforeAfter(
        before: _before!,
        after: _after!,
      );

      final now = DateTime.now();
      final isSafe = pred.label.toLowerCase().trim() == 'safe';

      // ⚠️ Replace TestOutcome.notDetected with your exact enum if different
      final mappedOutcome = isSafe
          ? TestOutcome.notDetected
          : (pred.isUnclear ? TestOutcome.detected /* or a custom "unclear" if you have */ : TestOutcome.detected);

      final localResult = TestResult(
        id: now.millisecondsSinceEpoch.toString(),
        time: now,
        type: _type,
        outcome: mappedOutcome,
        confidence: (pred.confidence * 100).round(),
        note: pred.isUnclear
            ? 'Model: ${pred.label} (Unclear: low confidence / close classes)'
            : 'Model: ${pred.label}',
        beforePath: _before!.path,
        afterPath: _after!.path,
      );
      addResult(localResult);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastPrediction = pred;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            prediction: pred,
            testType: _type,
            before: _before!,
            after: _after!,
            mergedPreviewPng: _mergedPreviewPng,

            onSaveToDatabase: () async {
              return await _storageService.saveChemicalTestPrivate(
                requestedUserId: widget.requestedUserId ?? "unknown_user",
                requestedDateTime: DateTime.now(),
                testType: _type,
                prediction: pred,
                before: _before!,
                after: _after!,
                mergedPreviewPng: _mergedPreviewPng,
                appointmentId: widget.appointmentId,
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Prediction failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Chemical Test'),
        actions: [
          IconButton(
            tooltip: 'Instructions',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstructionsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose test type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: TestType.values.map((t) {
                    final selected = t == _type;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(_testTypeLabel(t)),
                      onSelected: (_) => setState(() => _type = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      _modelReady ? Icons.check_circle : Icons.hourglass_top,
                      size: 18,
                      color: _modelReady ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _modelReady ? 'ML model ready' : 'Loading ML model...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text('Before photo (LEFT)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PhotoPickerCard(
            file: _before,
            onCamera: () => _pickBefore(ImageSource.camera),
            onGallery: () => _pickBefore(ImageSource.gallery),
          ),
          const SizedBox(height: 14),

          Text('After photo (RIGHT)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PhotoPickerCard(
            file: _after,
            onCamera: () => _pickAfter(ImageSource.camera),
            onGallery: () => _pickAfter(ImageSource.gallery),
          ),

          if (_before != null && _after != null) ...[
            const SizedBox(height: 14),
            Text('Combined image (sent to model)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MergedPreviewCard(bytes: _mergedPreviewPng),
          ],

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: (_busy || !_modelReady) ? null : _analyze,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Analyzing...' : 'Analyze with ML'),
          ),

          if (_lastPrediction != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last: ${_lastPrediction!.label} • ${(100 * _lastPrediction!.confidence).toStringAsFixed(1)}%${_lastPrediction!.isUnclear ? ' (Unclear)' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(_prettyProbs(_lastPrediction!), style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// Helper widgets (Internal to this file)
class _MergedPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  const _MergedPreviewCard({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: bytes == null
            ? const Center(child: CircularProgressIndicator())
            : Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
    );
  }
}
