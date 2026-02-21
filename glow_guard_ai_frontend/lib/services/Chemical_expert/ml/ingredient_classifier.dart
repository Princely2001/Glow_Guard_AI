import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlPrediction {
  final String label;
  final double confidence; // 0..1
  final List<double> probs;

  // ✅ Added: clarity/uncertainty metrics
  final bool isUnclear;
  final int bestIndex;
  final int secondBestIndex;
  final double margin; // bestProb - secondProb

  const MlPrediction({
    required this.label,
    required this.confidence,
    required this.probs,
    required this.isUnclear,
    required this.bestIndex,
    required this.secondBestIndex,
    required this.margin,
  });
}

class IngredientClassifier {
  //  Updated Model Asset Name
  static const String modelAsset = 'assets/ml/glowguard_efficientnet.tflite';
  static const String labelsAsset = 'assets/ml/labels.txt';

  //  Updated Input Dimensions for Single-Stream (Side-by-Side)
  // The model expects Height: 224, Width: 448
  static const int inputHeight = 224;
  static const int inputWidth = 448;

  // Each individual image (Before/After) is resized to 224x224 before merging
  static const int singleImageSize = 224;

  // UI preview size (2:1 aspect ratio)
  static const int previewWidth = 448;
  static const int previewHeight = 224;

  //  Unclear prediction thresholds
  static const double unclearConfidenceThreshold = 0.60;
  static const double unclearMarginThreshold = 0.15;

  Interpreter? _interpreter;
  List<String> _labels = const [];

  bool get isLoaded => _interpreter != null && _labels.isNotEmpty;

  Future<void> load({int threads = 2}) async {
    _labels = (await rootBundle.loadString(labelsAsset))
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_labels.isEmpty) {
      throw StateError('labels.txt is empty or not loaded.');
    }

    final options = InterpreterOptions()..threads = threads;
    _interpreter = await Interpreter.fromAsset(modelAsset, options: options);
    _interpreter!.allocateTensors();

    final inTensor = _interpreter!.getInputTensor(0);
    final outTensor = _interpreter!.getOutputTensor(0);

    // ignore: avoid_print
    print('TFLite input: shape=${inTensor.shape} type=${inTensor.type}'); // Should be [1, 224, 448, 3]
    // ignore: avoid_print
    print('Labels (${_labels.length}): $_labels');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  ///  Builds a merged preview PNG (Before LEFT, After RIGHT)
  Future<Uint8List> buildMergedPreviewPng({
    required File before,
    required File after,
  }) async {
    // Merge at high quality for UI
    final merged = await _mergeSideBySide(before: before, after: after, targetHeight: previewHeight, targetWidth: previewWidth);
    return Uint8List.fromList(img.encodePng(merged));
  }

  /// Predict using merged 224x448 image
  Future<MlPrediction> predictMergedBeforeAfter({
    required File before,
    required File after,
  }) async {
    final interpreter = _interpreter;
    if (interpreter == null) throw StateError('Model not loaded. Call load() first.');

    // 1. Prepare Image: 224x448
    final merged = await _mergeSideBySide(
        before: before,
        after: after,
        targetHeight: inputHeight,
        targetWidth: inputWidth
    );

    // 2. Preprocess: EfficientNet expects [0, 255] float inputs
    final input = _imageToEfficientNetInput(merged);

    // 3. Allocate Output
    final outShape = interpreter.getOutputTensor(0).shape;
    final outLen = outShape.isNotEmpty ? outShape.last : _labels.length;
    final output = List.generate(1, (_) => List.filled(outLen, 0.0));

    // 4. Run Inference
    interpreter.run(input, output);

    // 5. Process Results
    final raw = output[0].map((e) => e.toDouble()).toList();
    final probs = _ensureProbabilities(raw);

    // Find best and second-best
    int bestIdx = 0;
    int secondIdx = 0;
    double best = probs[0];
    double second = double.negativeInfinity;

    for (int i = 1; i < probs.length; i++) {
      final v = probs[i];
      if (v > best) {
        second = best;
        secondIdx = bestIdx;
        best = v;
        bestIdx = i;
      } else if (v > second) {
        second = v;
        secondIdx = i;
      }
    }

    final margin = (best - second).isFinite ? (best - second) : 0.0;
    final isUnclear = (best < unclearConfidenceThreshold) || (margin < unclearMarginThreshold);

    final label = bestIdx < _labels.length ? _labels[bestIdx] : 'Unknown';

    return MlPrediction(
      label: label,
      confidence: best,
      probs: probs,
      isUnclear: isUnclear,
      bestIndex: bestIdx,
      secondBestIndex: secondIdx,
      margin: margin,
    );
  }

  // ----------------- helpers -----------------

  /// Merges two images side-by-side.
  Future<img.Image> _mergeSideBySide({
    required File before,
    required File after,
    required int targetHeight,
    required int targetWidth,
  }) async {
    final b = _decodeAndFixOrientation(await before.readAsBytes());
    final a = _decodeAndFixOrientation(await after.readAsBytes());

    // Each side takes up half the width
    final halfWidth = (targetWidth / 2).round();

    // Resize both to fit their half
    final left = img.copyResize(b, width: halfWidth, height: targetHeight, interpolation: img.Interpolation.linear);
    final right = img.copyResize(a, width: halfWidth, height: targetHeight, interpolation: img.Interpolation.linear);

    final canvas = img.Image(width: targetWidth, height: targetHeight);
    img.compositeImage(canvas, left, dstX: 0, dstY: 0);
    img.compositeImage(canvas, right, dstX: halfWidth, dstY: 0);

    return canvas;
  }

  img.Image _decodeAndFixOrientation(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image.');
    return img.bakeOrientation(decoded);
  }

  ///  EfficientNet Input: [1, 224, 448, 3]
  List<List<List<List<double>>>> _imageToEfficientNetInput(img.Image imageWide) {
    final input = List.generate(
      1,
          (_) => List.generate(
        inputHeight,
            (_) => List.generate(inputWidth, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final p = imageWide.getPixel(x, y);

        // EfficientNet B0 (Keras default) expects 0..255
        input[0][y][x][0] = p.r.toDouble();
        input[0][y][x][1] = p.g.toDouble();
        input[0][y][x][2] = p.b.toDouble();
      }
    }
    return input;
  }

  List<double> _ensureProbabilities(List<double> raw) {
    final sum = raw.fold(0.0, (a, b) => a + b);
    final in01 = raw.every((v) => v >= 0.0 && v <= 1.0);

    if (in01 && sum > 0.98 && sum < 1.02) return raw;
    return _softmax(raw);
  }

  List<double> _softmax(List<double> x) {
    final maxVal = x.reduce(math.max);
    final exps = x.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }
}