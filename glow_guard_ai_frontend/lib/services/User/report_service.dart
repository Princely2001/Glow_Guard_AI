import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submits the report to Firestore and uploads the image to Firebase Storage
  Future<void> submitDangerousProductReport({
    required String productName,
    required String brand,
    required bool isAnonymous,
    required String timelineLabel,
    required String sideEffects,
    required double severity,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      final uid = _auth.currentUser?.uid;

      // 1. Upload Image to Firebase Storage (if selected)
      if (imageFile != null) {
        // Create a unique file name using timestamp
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        final storageRef = _storage.ref().child('dangerous_reports/$fileName');

        // Upload the file
        final uploadTask = await storageRef.putFile(imageFile);

        // Get the downloadable URL
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // 2. Save the report details to Cloud Firestore
      await _firestore.collection('dangerous_product_reports').add({
        'productName': productName,
        'brand': brand,
        'isAnonymous': isAnonymous,
        'reportedByUserId': isAnonymous ? 'anonymous' : uid,
        'reactionTimeline': timelineLabel,
        'sideEffectsDescription': sideEffects,
        'severityLevel': severity,
        'evidenceImageUrl': imageUrl,
        'status': 'Pending Review', // Default status for admins to review
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Failed to submit report: $e");
    }
  }
}