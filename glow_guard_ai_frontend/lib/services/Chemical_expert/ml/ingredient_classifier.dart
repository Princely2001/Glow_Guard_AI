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

  const MlPrediction({
    required this.label,
    required this.confidence,
    required this.probs,
  });
}

class IngredientClassifier {
  static const String modelAsset = 'assets/ml/best_ingredient_model.tflite';
  static const String labelsAsset = 'assets/ml/labels.txt';

  static const int inputSize = 224;
  static const int halfW = 112;
  static const int halfH = 224;

  // UI preview size (bigger than model input)
  static const int previewSize = 448;

  Interpreter? _interpreter;
  List<String> _labels = const [];

  bool get isLoaded => _interpreter != null && _labels.isNotEmpty;

  Future<void> load({int threads = 2}) async {
    _labels = (await rootBundle.loadString(labelsAsset))
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_labels.isEmpty) {
      throw StateError('labels.txt is empty or not loaded.');
    }

    final options = InterpreterOptions()..threads = threads;
    _interpreter = await Interpreter.fromAsset(modelAsset, options: options);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// ✅ Builds a merged preview PNG (Before LEFT, After RIGHT) for displaying on screen
  Future<Uint8List> buildMergedPreviewPng({
    required File before,
    required File after,
    int size = previewSize,
  }) async {
    final merged = await _mergeSideBySideSquare(before: before, after: after, size: size);
    return Uint8List.fromList(img.encodePng(merged));
  }

  Future<img.Image> _mergeSideBySideSquare({
    required File before,
    required File after,
    required int size,
  }) async {
    final b = _decodeAndFixOrientation(await before.readAsBytes());
    final a = _decodeAndFixOrientation(await after.readAsBytes());

    final half = (size / 2).round();

    final left = img.copyResize(b, width: half, height: size, interpolation: img.Interpolation.linear);
    final right = img.copyResize(a, width: half, height: size, interpolation: img.Interpolation.linear);

    final canvas = img.Image(width: size, height: size);
    img.compositeImage(canvas, left, dstX: 0, dstY: 0);
    img.compositeImage(canvas, right, dstX: half, dstY: 0);

    return canvas;
  }

  /// ✅ Predict using merged 224x224 image:
  /// LEFT = Before (112x224), RIGHT = After (112x224)
  Future<MlPrediction> predictMergedBeforeAfter({
    required File before,
    required File after,
  }) async {
    final interpreter = _interpreter;
    if (interpreter == null) throw StateError('Model not loaded. Call load() first.');

    final merged = await _mergeSideBySide224(before: before, after: after);

    // ✅ Same as tf.keras.applications.mobilenet_v2.preprocess_input:
    // (x / 127.5) - 1.0  => [-1, 1]
    final input = _imageToMobileNetV2Input(merged);

    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    interpreter.run(input, output);

    final raw = output[0].map((e) => e.toDouble()).toList();
    final probs = _ensureProbabilities(raw);

    int bestIdx = 0;
    double best = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > best) {
        best = probs[i];
        bestIdx = i;
      }
    }

    final label = bestIdx < _labels.length ? _labels[bestIdx] : 'Unknown';
    return MlPrediction(label: label, confidence: best, probs: probs);
  }

  // ----------------- helpers -----------------

  Future<img.Image> _mergeSideBySide224({
    required File before,
    required File after,
  }) async {
    final b = _decodeAndFixOrientation(await before.readAsBytes());
    final a = _decodeAndFixOrientation(await after.readAsBytes());

    // IMPORTANT: match training (resize only, no crop)
    final left = img.copyResize(b, width: halfW, height: halfH, interpolation: img.Interpolation.linear);
    final right = img.copyResize(a, width: halfW, height: halfH, interpolation: img.Interpolation.linear);

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.compositeImage(canvas, left, dstX: 0, dstY: 0);
    img.compositeImage(canvas, right, dstX: halfW, dstY: 0);

    return canvas;
  }

  img.Image _decodeAndFixOrientation(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image.');
    return img.bakeOrientation(decoded);
  }

  /// ✅ image package v4+ pixel safe conversion
  /// Produces [1,224,224,3] doubles in RGB order, normalized to [-1,1]
  List<List<List<List<double>>>> _imageToMobileNetV2Input(img.Image image224) {
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = image224.getPixel(x, y); // Pixel (not int)

        final r = (p.r.toDouble() / 127.5) - 1.0;
        final g = (p.g.toDouble() / 127.5) - 1.0;
        final b = (p.b.toDouble() / 127.5) - 1.0;

        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
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
