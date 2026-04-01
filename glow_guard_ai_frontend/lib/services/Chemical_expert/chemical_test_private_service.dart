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

  // Keep your existing collection name to avoid breaking current data.
  static const String _collectionName = 'chemical test private';

  ChemicalTestPrivateService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Helper: Uploads a file and waits for it to finish before getting the URL
  Future<String> _uploadFileSafe(Reference ref, File file) async {
    try {
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (task.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${task.state}");
      }
    } catch (e) {
      print("❌ Error uploading to ${ref.fullPath}: $e");
      rethrow;
    }
  }

  /// Helper: Uploads raw data (for merged image) safe
  Future<String> _uploadDataSafe(Reference ref, Uint8List data) async {
    try {
      final task = await ref.putData(
        data,
        SettableMetadata(contentType: 'image/png'),
      );

      if (task.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception("Merged upload failed with state: ${task.state}");
      }
    } catch (e) {
      print("❌ Error uploading merged image: $e");
      return ""; // non-critical
    }
  }

  /// ✅ Save record using a UNIQUE Firestore auto-id (no overwrites).
  Future<String> saveChemicalTestPrivate({
    required String requestedUserId,
    required DateTime requestedDateTime,
    required TestType testType,
    required MlPrediction prediction,
    required File before,
    required File after,
    Uint8List? mergedPreviewPng,
    String? appointmentId,
    required String expertNote, // ✅ Updated to required String expertNote
  }) async {
    final expert = _auth.currentUser;
    if (expert == null) {
      throw Exception("You must be logged in as an expert to save results.");
    }

    // ✅ Unique ID (Firestore auto-id)
    final docRef = _db.collection(_collectionName).doc();
    final recordId = docRef.id;

    // --- Storage References (also unique per record) ---
    final basePath = 'chemical_test_private/$recordId';
    final beforeRef = _storage.ref('$basePath/before.jpg');
    final afterRef = _storage.ref('$basePath/after.jpg');
    final mergedRef = _storage.ref('$basePath/merged.png');

    // --- Upload images ---
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

      // (Optional but useful) store storage paths too
      "beforeImagePath": beforeRef.fullPath,
      "afterImagePath": afterRef.fullPath,
      "mergedImagePath": mergedRef.fullPath,

      "expertNote": expertNote, // ✅ Using the expertNote parameter
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return recordId;
  }

  // ============================================================
  // ✅ PROFESSIONAL TEST REQUEST (ADDED)
  // ============================================================
  Future<String> requestProfessionalTest({
    required String requestedUserId,
    required DateTime requestedDateTime,
    required TestType testType,
    required MlPrediction prediction,
    required File before,
    required File after,
    Uint8List? mergedPreviewPng,
    String? appointmentId,
    required String expertNote,
  }) async {
    final expert = _auth.currentUser;
    if (expert == null) {
      throw Exception("You must be logged in as an expert to request a professional test.");
    }

    // ✅ Create a new collection for professional test requests
    final docRef = _db.collection('professional_test_requests').doc();
    final requestId = docRef.id;

    // --- Storage References ---
    final basePath = 'professional_test_requests/$requestId';
    final beforeRef = _storage.ref('$basePath/before.jpg');
    final afterRef = _storage.ref('$basePath/after.jpg');
    final mergedRef = _storage.ref('$basePath/merged.png');

    // --- Upload images ---
    final beforeUrl = await _uploadFileSafe(beforeRef, before);
    final afterUrl = await _uploadFileSafe(afterRef, after);

    String mergedUrl = "";
    if (mergedPreviewPng != null && mergedPreviewPng.isNotEmpty) {
      mergedUrl = await _uploadDataSafe(mergedRef, mergedPreviewPng);
    }

    // --- Save to Firestore ---
    await docRef.set({
      "requestId": requestId,
      "requestedUserId": requestedUserId,
      "requestedDateTime": Timestamp.fromDate(requestedDateTime),

      "requestingExpertId": expert.uid,
      "requestingExpertEmail": expert.email ?? "",

      "appointmentId": appointmentId ?? "",
      "testType": testType.toString().split('.').last,

      "predictionLabel": prediction.label,
      "confidence": prediction.confidence,
      "probs": prediction.probs,

      "beforeImageUrl": beforeUrl,
      "afterImageUrl": afterUrl,
      "mergedImageUrl": mergedUrl,

      "expertNote": expertNote,
      "status": "pending_lab_review", // Indicates it's awaiting professional action

      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return requestId;
  }

  // ============================================================
  // ✅ PROFESSIONAL TEST REQUESTS STREAM (ALL EXPERTS)
  // ============================================================

  /// Stream ALL professional test requests for the lab submission dashboard
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllProfessionalRequests({
    int limit = 100,
  }) {
    return _db
        .collection('professional_test_requests')
        .orderBy('requestedDateTime', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ============================================================
  // ✅ CHEMICAL EXPERT HISTORY
  // ============================================================

  /// Stream expert test history (live updates).
  /// Good for a "History" screen with a StreamBuilder.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchExpertHistory({
    int limit = 50,
  }) {
    final expert = _auth.currentUser;
    if (expert == null) {
      // Return empty stream instead of throwing (nicer for UI)
      return const Stream.empty();
    }

    return _db
        .collection(_collectionName)
        .where('expertId', isEqualTo: expert.uid)
        .orderBy('requestedDateTime', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Paginated fetch (for infinite scroll).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchExpertHistoryPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    final expert = _auth.currentUser;
    if (expert == null) {
      throw Exception("You must be logged in as an expert.");
    }

    Query<Map<String, dynamic>> q = _db
        .collection(_collectionName)
        .where('expertId', isEqualTo: expert.uid)
        .orderBy('requestedDateTime', descending: true)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    return await q.get();
  }

  /// Get a single test record by recordId (for detail view).
  Future<DocumentSnapshot<Map<String, dynamic>>> getTestById(String recordId) async {
    return await _db.collection(_collectionName).doc(recordId).get();
  }
}