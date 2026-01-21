import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertScheduleService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  ExpertScheduleService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  String _dateKey(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    final y = dd.year.toString().padLeft(4, '0');
    final m = dd.month.toString().padLeft(2, '0');
    final day = dd.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Read slots for a given date
  Future<List<String>> getAvailabilitySlots(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: "firebase_auth",
        message: "Not logged in.",
      );
    }

    final key = _dateKey(date);

    final doc = await _db
        .collection('experts')
        .doc(uid)
        .collection('availability')
        .doc(key)
        .get();

    if (!doc.exists) return [];

    final data = doc.data() ?? {};
    final slots = (data['slots'] as List?)?.map((e) => e.toString()).toList() ?? [];
    slots.sort();
    return slots;
  }

  /// Save availability slots for a given date
  Future<void> setAvailability({
    required DateTime date,
    required List<String> slots,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: "firebase_auth",
        message: "Not logged in.",
      );
    }

    final key = _dateKey(date);
    final cleanSlots = slots.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();

    await _db
        .collection('experts')
        .doc(uid)
        .collection('availability')
        .doc(key)
        .set({
      "date": key,
      "slots": cleanSlots,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateHasUpcomingAvailability(uid);
  }

  /// ✅ Clear availability for a date (THIS FIXES YOUR ERROR)
  Future<void> clearAvailability({required DateTime date}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: "firebase_auth",
        message: "Not logged in.",
      );
    }

    final key = _dateKey(date);

    await _db
        .collection('experts')
        .doc(uid)
        .collection('availability')
        .doc(key)
        .delete();

    await _updateHasUpcomingAvailability(uid);
  }

  /// Updates experts/{uid}.hasUpcomingAvailability for next 30 days
  Future<void> _updateHasUpcomingAvailability(String uid) async {
    final start = _today();
    final end = start.add(const Duration(days: 30));

    // We store docs by "YYYY-MM-DD", so query by "date" string range.
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    final q = await _db
        .collection('experts')
        .doc(uid)
        .collection('availability')
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThanOrEqualTo: endKey)
        .get();

    bool hasAny = false;
    for (final d in q.docs) {
      final slots = (d.data()['slots'] as List?) ?? [];
      if (slots.isNotEmpty) {
        hasAny = true;
        break;
      }
    }

    await _db.collection('experts').doc(uid).set({
      "hasUpcomingAvailability": hasAny,
      "availabilityUpdatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
