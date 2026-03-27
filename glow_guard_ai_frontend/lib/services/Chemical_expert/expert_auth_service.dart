import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ExpertRegisterData {
  final String title;
  final String name;
  final String email;
  final String contactNumber;
  final String govRegistrationId; // ✅ Added Government Registration ID
  final DateTime dateOfBirth;
  final int experienceYears;
  final String educationLevel;
  final String location; // ✅ Added location (City/District)
  final String password;
  final File? credentialFile;

  const ExpertRegisterData({
    required this.title,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.govRegistrationId, // ✅ Required parameter
    required this.dateOfBirth,
    required this.experienceYears,
    required this.educationLevel,
    required this.location, // ✅ Added location
    required this.password,
    required this.credentialFile,
  });

  String get callingName => "$title$name";
}

class ExpertAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ExpertAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// ✅ Register expert -> Status ALWAYS "pending" until Admin Approval
  Future<void> registerExpert(ExpertRegisterData data) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: data.email.trim(),
      password: data.password,
    );

    final uid = cred.user?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: "missing-uid",
        message: "Registration failed: missing user id.",
      );
    }

    String? certificateUrl;

    // ✅ Upload credential document to Firebase Storage
    if (data.credentialFile != null) {
      final ext = data.credentialFile!.path.split('.').last;
      final ref = _storage.ref().child('expert_credentials/$uid.$ext');
      await ref.putFile(data.credentialFile!);
      certificateUrl = await ref.getDownloadURL();
    }

    // ✅ STRICT POLICY: All new accounts are pending
    const status = "pending";

    await _db.collection('experts').doc(uid).set({
      "uid": uid,
      "role": "expert",
      "title": data.title,
      "name": data.name.trim(),
      "callingName": data.callingName,
      "email": data.email.trim(),
      "contactNumber": data.contactNumber.trim(),
      "govRegistrationId": data.govRegistrationId.trim(), // ✅ Save Gov ID to Firestore
      "dateOfBirth": Timestamp.fromDate(data.dateOfBirth),
      "chemicalTestingExperienceYears": data.experienceYears,
      "educationLevel": data.educationLevel,
      "location": data.location, // ✅ Save the location to Firestore
      "credentialUrl": certificateUrl,
      "status": status,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Expert login -> must exist in experts/{uid} and status must be active
  Future<String> loginExpert({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user?.uid;
    if (uid == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: "missing-uid",
        message: "Login failed: missing user id.",
      );
    }

    final snap = await _db.collection('experts').doc(uid).get();
    if (!snap.exists) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: "not-expert",
        message: "Access denied: this account is not registered as an expert.",
      );
    }

    final status = (snap.data()?['status'] ?? 'pending').toString().toLowerCase();

    // ✅ Handle Admin Verification block
    if (status == "pending") {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: "expert-pending",
        message: "Your account is pending Admin Verification. We will notify you once your credentials are approved.",
      );
    } else if (status == "rejected") {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: "expert-rejected",
        message: "Your application was rejected. Please contact support.",
      );
    }

    return uid;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}