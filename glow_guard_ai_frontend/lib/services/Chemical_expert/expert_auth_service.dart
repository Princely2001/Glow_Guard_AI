import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertRegisterData {
  final String title; // Dr., Mr., ...
  final String name; // Smith
  final String email;
  final String contactNumber;
  final DateTime dateOfBirth;
  final int experienceYears; // 0..30
  final String educationLevel; // BSc 1st / MSc / PhD
  final String password;

  const ExpertRegisterData({
    required this.title,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.dateOfBirth,
    required this.experienceYears,
    required this.educationLevel,
    required this.password,
  });

  String get callingName => "$title$name"; // Dr.Smith
}

class ExpertAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  ExpertAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  /// ✅ Register expert -> Auth + experts/{uid}
  /// ✅ Auto-approve if experienceYears > 5
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

    // ✅ Auto approval rule
    final status = data.experienceYears > 5 ? "active" : "pending";

    await _db.collection('experts').doc(uid).set({
      "uid": uid,
      "role": "expert",
      "title": data.title,
      "name": data.name.trim(),
      "callingName": data.callingName,
      "email": data.email.trim(),
      "contactNumber": data.contactNumber.trim(),
      "dateOfBirth": Timestamp.fromDate(data.dateOfBirth),
      "chemicalTestingExperienceYears": data.experienceYears,
      "educationLevel": data.educationLevel,
      "status": status,
      "createdAt": FieldValue.serverTimestamp(),
      if (status == "active") "approvedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Expert login -> must exist in experts/{uid} and status must be active
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
    if (status != "active") {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: "expert-pending",
        message: "Your expert account is pending approval (experience must be > 5 years).",
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
