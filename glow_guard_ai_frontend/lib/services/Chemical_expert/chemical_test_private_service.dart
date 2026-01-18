import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/models/test_models.dart';
import 'ml/ingredient_classifier.dart';

class ChemicalTestPrivateService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ChemicalTestPrivateService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String buildRecordId(DateTime requestedDateTime) {
    final y = requestedDateTime.year.toString().padLeft(4, '0');
    final m = requestedDateTime.month.toString().padLeft(2, '0');
    final d = requestedDateTime.day.toString().padLeft(2, '0');

    final hour24 = requestedDateTime.hour;
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;

    return '$y$m$d$hour12$ampm';
  }

  /// Helper: Uploads a file and waits for it to finish before getting the URL
  Future<String> _uploadFileSafe(Reference ref, File file) async {
    try {
      // 1. Perform the upload
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

      // 2. Check if upload actually succeeded
      if (task.state == TaskState.success) {
        // 3. ONLY now ask for the URL
        return await ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${task.state}");
      }
    } catch (e) {
      print("❌ Error uploading to ${ref.fullPath}: $e");
      // Rethrow so the app knows the save failed
      rethrow;
    }
  }

  /// Helper: Uploads raw data (for merged image) safe
  Future<String> _uploadDataSafe(Reference ref, Uint8List data) async {
    try {
      final task = await ref.putData(data, SettableMetadata(contentType: 'image/png'));
      if (task.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception("Merged upload failed with state: ${task.state}");
      }
    } catch (e) {
      print("❌ Error uploading merged image: $e");
      return ""; // Return empty string if merged preview fails (non-critical)
    }
  }

  Future<String> saveChemicalTestPrivate({
    required String requestedUserId,
    required DateTime requestedDateTime,
    required TestType testType,
    required MlPrediction prediction,
    required File before,
    required File after,
    Uint8List? mergedPreviewPng,
    String? appointmentId,
    String? note,
  }) async {
    final expert = _auth.currentUser;
    if (expert == null) {
      throw Exception("You must be logged in as an expert to save results.");
    }

    final recordId = buildRecordId(requestedDateTime);
    final docRef = _db.collection('chemical test private').doc(recordId);

    // Optional: Check existence (removed for speed, Firestore overwrites by default)

    // --- Storage References ---
    final basePath = 'chemical_test_private/$recordId';
    final beforeRef = _storage.ref('$basePath/before.jpg');
    final afterRef = _storage.ref('$basePath/after.jpg');
    final mergedRef = _storage.ref('$basePath/merged.png');

    // --- Execute Uploads sequentially or carefully parallel ---
    // We use the safe helper functions created above.

    final beforeUrl = await _uploadFileSafe(beforeRef, before);
    final afterUrl = await _uploadFileSafe(afterRef, after);

    String mergedUrl = "";
    if (mergedPreviewPng != null && mergedPreviewPng.isNotEmpty) {
      mergedUrl = await _uploadDataSafe(mergedRef, mergedPreviewPng);
    }

    // --- Save to Firestore ---
    await docRef.set({
      "recordId": recordId,
      "requestedUserId": requestedUserId,
      "requestedDateTime": Timestamp.fromDate(requestedDateTime),

      "expertId": expert.uid,
      "expertEmail": expert.email ?? "",

      "appointmentId": appointmentId ?? "",
      "testType": testType.toString().split('.').last,

      "predictionLabel": prediction.label,
      "confidence": prediction.confidence,
      "probs": prediction.probs,

      "beforeImageUrl": beforeUrl,
      "afterImageUrl": afterUrl,
      "mergedImageUrl": mergedUrl,

      "note": note ?? "",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return recordId;
  }
}