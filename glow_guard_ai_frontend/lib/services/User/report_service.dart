import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submits the report to Firestore and uploads any attached images to Firebase Storage
  Future<void> submitDangerousProductReport({
    required String productName,
    required String brand,
    required bool isAnonymous,
    required List<Map<String, dynamic>> timelineData,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;

      // 1. Process each timeline entry to upload images if they exist
      List<Map<String, dynamic>> processedTimeline = [];

      for (var entry in timelineData) {
        String? imageUrl;
        File? imageFile = entry['imageFile'];

        if (imageFile != null) {
          // Create a unique file name using timestamp and stage
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${entry['stage'].replaceAll(' ', '_')}_${path.basename(imageFile.path)}';
          final storageRef = _storage.ref().child('dangerous_reports/$fileName');

          // Upload the file
          final uploadTask = await storageRef.putFile(imageFile);

          // Get the downloadable URL
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // Add the processed entry (with image URL instead of file object)
        processedTimeline.add({
          'stage': entry['stage'],
          'sideEffectsDescription': entry['sideEffects'],
          'severityLevel': entry['severity'],
          'evidenceImageUrl': imageUrl,
        });
      }

      // 2. Save the compiled report details to Cloud Firestore
      await _firestore.collection('dangerous_product_reports').add({
        'productName': productName,
        'brand': brand,
        'isAnonymous': isAnonymous,
        'reportedByUserId': isAnonymous ? 'anonymous' : uid,
        'timelineExperiences': processedTimeline, // Saved as an array of maps
        'status': 'Pending Review', // Default status for admins to review
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Failed to submit report: $e");
    }
  }
}