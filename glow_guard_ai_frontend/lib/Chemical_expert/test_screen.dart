import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/test_models.dart';
import '../widgets/common_widgets.dart';
import '../Chemical_expert/instructions_screen.dart';
import '../Chemical_expert/prediction_result_screen.dart';
import '../services/Chemical_expert/chemical_test_controller.dart'; // Import the new controller

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
  // Instantiate the controller once for this screen
  late final ChemicalTestController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChemicalTestController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _testTypeLabel(TestType t) => t.toString().split('.').last.toUpperCase();

  Future<void> _handleAnalyze() async {
    if (_controller.before == null || _controller.after == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add BOTH Before and After photos.')),
      );
      return;
    }

    try {
      final pred = await _controller.analyze();

      if (pred != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PredictionResultScreen(
              prediction: pred,
              testType: _controller.type,
              before: _controller.before!,
              after: _controller.after!,
              mergedPreviewPng: _controller.mergedPreviewPng,
              onSaveToDatabase: () => _controller.saveToDatabase(
                userId: widget.requestedUserId ?? "unknown_user",
                appointmentId: widget.appointmentId,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen())),
          ),
        ],
      ),
      // ListenableBuilder listens to the controller and rebuilds the UI when state changes
      body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose test type', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: TestType.values.map((t) {
                          return ChoiceChip(
                            selected: t == _controller.type,
                            label: Text(_testTypeLabel(t)),
                            onSelected: (_) => _controller.setTestType(t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                              _controller.modelReady ? Icons.check_circle : Icons.hourglass_top,
                              size: 18,
                              color: _controller.modelReady ? cs.primary : cs.onSurfaceVariant
                          ),
                          const SizedBox(width: 8),
                          Text(
                              _controller.modelReady ? 'ML model ready' : 'Loading ML model...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)
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
                    file: _controller.before,
                    onCamera: () => _controller.pickBefore(ImageSource.camera),
                    onGallery: () => _controller.pickBefore(ImageSource.gallery)
                ),
                const SizedBox(height: 14),

                Text('After photo (RIGHT)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                PhotoPickerCard(
                    file: _controller.after,
                    onCamera: () => _controller.pickAfter(ImageSource.camera),
                    onGallery: () => _controller.pickAfter(ImageSource.gallery)
                ),

                if (_controller.before != null && _controller.after != null) ...[
                  const SizedBox(height: 14),
                  Text('Combined Preview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _MergedPreviewCard(bytes: _controller.mergedPreviewPng),
                ],

                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: (_controller.busy || !_controller.modelReady) ? null : _handleAnalyze,
                  icon: _controller.busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_controller.busy ? 'Analyzing...' : 'Analyze with ML'),
                ),

                if (_controller.lastPrediction != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last: ${_controller.lastPrediction!.label} • ${(100 * _controller.lastPrediction!.confidence).toStringAsFixed(1)}%${_controller.lastPrediction!.isUnclear ? ' (Unclear)' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            );
          }
      ),
    );
  }
}

class _MergedPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  const _MergedPreviewCard({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: bytes == null
            ? const Center(child: CircularProgressIndicator())
            : Image.memory(bytes!, fit: BoxFit.contain),
      ),
    );
  }
}