import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

class UserRegisterData {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final DateTime dob;
  final String education;
  final String cosmeticExp;
  final String chemicalExp;
  final String password;

  const UserRegisterData({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.education,
    required this.cosmeticExp,
    required this.chemicalExp,
    required this.password,
  });
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> setupFCMToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();

      if (token != null) {
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    }
  }
}

class UserAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  static String generateUserId() {
    return "GG-${Random().nextInt(999999).toString().padLeft(6, '0')}-${DateTime.now().year}";
  }

  Future<String> registerUser(UserRegisterData data) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: data.password.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: "missing-uid",
          message: "Registration failed: missing user id.",
        );
      }

      await _db.collection('users').doc(uid).set({
        "uid": uid,
        "userId": data.userId,
        "name": data.name.trim(),
        "email": data.email.trim(),
        "phone": data.phone.trim(),
        "gender": data.gender,
        "dob": DateFormat("yyyy-MM-dd").format(data.dob),
        "education": data.education,
        "cosmeticExp": data.cosmeticExp,
        "chemicalExp": data.chemicalExp,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await NotificationService().setupFCMToken();

      return uid;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: "user-register-failed",
        message: "User registration failed: $e",
      );
    }
  }
}

class UserLoginService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserLoginService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'missing-uid',
          message: 'Login failed: missing user id.',
        );
      }

      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'no-user-profile',
          message: 'No user profile found in database for this account.',
        );
      }

      await NotificationService().setupFCMToken();

      return uid;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'user-login-failed',
        message: 'Login failed: $e',
      );
    }
  }

  // ✅ Already correctly implemented!
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}