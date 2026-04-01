import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/results_store.dart';
import '../../models/test_models.dart';
import '../../services/Chemical_expert/ml/ingredient_classifier.dart';
import '../../services/Chemical_expert/chemical_test_private_service.dart';

class ChemicalTestController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final ChemicalTestPrivateService _storageService = ChemicalTestPrivateService();
  final IngredientClassifier _clf = IngredientClassifier();

  // State Variables
  TestType type = TestType.mercury;
  File? before;
  File? after;
  Uint8List? mergedPreviewPng;

  bool busy = false;
  bool modelReady = false;
  MlPrediction? lastPrediction;

  int _mergeJob = 0;

  ChemicalTestController() {
    _loadModel();
  }

  // --- ML Initialization ---
  Future<void> _loadModel() async {
    try {
      await _clf.load(threads: 2);
      modelReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Model load failed: $e');
      throw Exception('Failed to load ML model: $e');
    }
  }

  // --- Image Handling ---
  void setTestType(TestType newType) {
    type = newType;
    notifyListeners();
  }

  Future<void> pickBefore(ImageSource src) async {
    final x = await _picker.pickImage(source: src);
    if (x == null) return;
    before = File(x.path);
    await _updateMergedPreview();
    notifyListeners();
  }

  Future<void> pickAfter(ImageSource src) async {
    final x = await _picker.pickImage(source: src);
    if (x == null) return;
    after = File(x.path);
    await _updateMergedPreview();
    notifyListeners();
  }

  Future<void> _updateMergedPreview() async {
    if (before == null || after == null) return;
    final job = ++_mergeJob;
    try {
      final bytes = await _clf.buildMergedPreviewPng(before: before!, after: after!);
      if (job == _mergeJob) {
        mergedPreviewPng = bytes;
      }
    } catch (e) {
      debugPrint('Preview merge failed: $e');
    }
  }

  // --- ML Execution ---
  Future<MlPrediction?> analyze() async {
    if (before == null || after == null || !modelReady) return null;

    busy = true;
    lastPrediction = null;
    notifyListeners();

    try {
      final pred = await _clf.predictMergedBeforeAfter(before: before!, after: after!);

      // Save Local Result History
      final now = DateTime.now();
      final isSafe = pred.label.toLowerCase().trim() == 'safe';
      final mappedOutcome = isSafe ? TestOutcome.notDetected : TestOutcome.detected;

      final localResult = TestResult(
        id: now.millisecondsSinceEpoch.toString(),
        time: now,
        type: type,
        outcome: mappedOutcome,
        confidence: (pred.confidence * 100).round(),
        note: pred.isUnclear ? 'Model: ${pred.label} (Unclear)' : 'Model: ${pred.label}',
        beforePath: before!.path,
        afterPath: after!.path,
      );
      addResult(localResult); // Global function from results_store.dart

      lastPrediction = pred;
      busy = false;
      notifyListeners();
      return pred;
    } catch (e) {
      busy = false;
      notifyListeners();
      throw Exception('Analysis failed: $e');
    }
  }

  // --- Backend/Database Action ---
  Future<String> saveToDatabase({required String userId, String? appointmentId, required String expertNote}) async {
    if (before == null || after == null || lastPrediction == null) return "";
    return await _storageService.saveChemicalTestPrivate(
      requestedUserId: userId,
      requestedDateTime: DateTime.now(),
      testType: type,
      prediction: lastPrediction!,
      before: before!,
      after: after!,
      mergedPreviewPng: mergedPreviewPng,
      appointmentId: appointmentId,
      expertNote: expertNote, // Passing the expert note to the service
    );
  }

  Future<String> requestProfessionalTest({required String userId, String? appointmentId, required String expertNote}) async {
    if (before == null || after == null || lastPrediction == null) return "";
    // Note: You must create this `requestProfessionalTest` function inside your ChemicalTestPrivateService
    // to handle saving to the professional test requests database.
    return await _storageService.requestProfessionalTest(
      requestedUserId: userId,
      requestedDateTime: DateTime.now(),
      testType: type,
      prediction: lastPrediction!,
      before: before!,
      after: after!,
      mergedPreviewPng: mergedPreviewPng,
      appointmentId: appointmentId,
      expertNote: expertNote,
    );
  }

  @override
  void dispose() {
    _clf.dispose();
    super.dispose();
  }
}