import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/results_store.dart';
import '../../models/test_models.dart';
import '../../services/Chemical_expert/ml/ingredient_classifier.dart';
import '../../services/Chemical_expert/chemical_test_private_service.dart';

class ChemicalTestController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final ChemicalTestPrivateService _storageService =
  ChemicalTestPrivateService();
  final IngredientClassifier _clf = IngredientClassifier();

  // State
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

  // ---------------- ML Initialization ----------------
  Future<void> _loadModel() async {
    try {
      await _clf.load(threads: 2);
      modelReady = true;
    } catch (e) {
      modelReady = false;
      debugPrint('Model load failed: $e');
      throw Exception('Failed to load ML model: $e');
    } finally {
      notifyListeners();
    }
  }

  // ---------------- UI State ----------------
  void setTestType(TestType newType) {
    type = newType;
    notifyListeners();
  }

  // ---------------- Image Picking ----------------
  Future<void> pickBefore(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 85);
    if (x == null) return;

    before = File(x.path);
    await _updateMergedPreview();
    notifyListeners();
  }

  Future<void> pickAfter(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 85);
    if (x == null) return;

    after = File(x.path);
    await _updateMergedPreview();
    notifyListeners();
  }

  Future<void> _updateMergedPreview() async {
    if (before == null || after == null) {
      mergedPreviewPng = null;
      return;
    }

    final job = ++_mergeJob;

    try {
      final bytes =
      await _clf.buildMergedPreviewPng(before: before!, after: after!);

      if (job == _mergeJob) {
        mergedPreviewPng = bytes;
      }
    } catch (e) {
      debugPrint('Preview merge failed: $e');
      mergedPreviewPng = null;
    }
  }

  // ---------------- ML Analyze ----------------
  Future<MlPrediction?> analyze() async {
    if (before == null || after == null) {
      throw Exception('Please select both before and after images.');
    }

    if (!modelReady) {
      throw Exception('ML model is not ready yet.');
    }

    busy = true;
    lastPrediction = null;
    notifyListeners();

    try {
      final pred = await _clf.predictMergedBeforeAfter(
        before: before!,
        after: after!,
      );

      final now = DateTime.now();
      final isSafe = pred.label.toLowerCase().trim() == 'safe';
      final mappedOutcome =
      isSafe ? TestOutcome.notDetected : TestOutcome.detected;

      final localResult = TestResult(
        id: now.millisecondsSinceEpoch.toString(),
        time: now,
        type: type,
        outcome: mappedOutcome,
        confidence: (pred.confidence * 100).round(),
        note: pred.isUnclear
            ? 'Model: ${pred.label} (Unclear)'
            : 'Model: ${pred.label}',
        beforePath: before!.path,
        afterPath: after!.path,
      );

      addResult(localResult);

      lastPrediction = pred;
      return pred;
    } catch (e) {
      throw Exception('Analysis failed: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------- Save Result + Mark Appointment Completed ----------------
  Future<String> saveToDatabase({
    required String userId,
    String? appointmentId,
    required String expertNote,
  }) async {
    if (before == null || after == null || lastPrediction == null) {
      throw Exception('Missing test data. Please run the chemical test first.');
    }

    final recordId = await _storageService.saveChemicalTestPrivate(
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

    // Mark related appointment as completed after successful save
    if (appointmentId != null && appointmentId.trim().isNotEmpty) {
      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'completed',
        'chemicalStatus': 'completed',
        'testStatus': 'completed',
        'chemicalTestDone': true,
        'resultSaved': true,
        'completedAt': now,
        'updatedAt': now,
        'chemicalTestResultId': recordId,
      });
    }

    return recordId;
  }

  // ---------------- Request Professional Test ----------------
  Future<String> requestProfessionalTest({
    required String userId,
    String? appointmentId,
    required String expertNote,
  }) async {
    if (before == null || after == null || lastPrediction == null) {
      throw Exception('Missing test data. Please run the chemical test first.');
    }

    final requestId = await _storageService.requestProfessionalTest(
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

    if (appointmentId != null && appointmentId.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'chemicalStatus': 'requested_professional_test',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return requestId;
  }

  @override
  void dispose() {
    _clf.dispose();
    super.dispose();
  }
}