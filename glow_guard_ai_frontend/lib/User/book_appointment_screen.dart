import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'appointment_details_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String expertId;
  final String expertName;
  final String expertSpecialty;
  final String expertPhotoUrl;

  const BookAppointmentScreen({
    super.key,
    required this.expertId,
    required this.expertName,
    required this.expertSpecialty,
    required this.expertPhotoUrl,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedDateId; // "YYYY-MM-DD"
  String? _selectedSlot;
  bool _busy = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ----------------- BOOK -----------------
  Future<void> _book() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Not logged in.");
      return;
    }
    if (_selectedDateId == null || _selectedSlot == null) {
      _snack("Select date and time first.");
      return;
    }

    setState(() => _busy = true);

    try {
      final availRef = _db
          .collection('experts')
          .doc(widget.expertId)
          .collection('availability')
          .doc(_selectedDateId);

      final apptRef = _db.collection('appointments').doc();
      final dateMidnight = _parseDateId(_selectedDateId!);

      await _db.runTransaction((tx) async {
        final availSnap = await tx.get(availRef);
        if (!availSnap.exists) {
          throw Exception("This date is no longer available.");
        }

        final data = (availSnap.data() as Map<String, dynamic>?) ?? {};
        final slots = ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();

        if (!slots.contains(_selectedSlot)) {
          throw Exception("This time slot was already booked.");
        }

        slots.remove(_selectedSlot);

        if (slots.isEmpty) {
          tx.delete(availRef);
        } else {
          tx.update(availRef, {
            "slots": slots,
            "updatedAt": FieldValue.serverTimestamp(),
            "date": Timestamp.fromDate(dateMidnight), // ✅ keep date for admin usage
          });
        }

        tx.set(apptRef, {
          "userId": user.uid,
          "userEmail": user.email ?? "",
          "expertId": widget.expertId,
          "expertName": widget.expertName,
          "expertSpecialty": widget.expertSpecialty,
          "expertPhotoUrl": widget.expertPhotoUrl,
          "dateId": _selectedDateId,
          "date": Timestamp.fromDate(dateMidnight),
          "slot": _selectedSlot,
          "status": "booked",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      _snack("Appointment booked ✅");

      // ✅ keep selected date+slot, or reset:
      setState(() {
        _selectedSlot = null;
        // _selectedDateId = null; // uncomment if you want clear date too
      });
    } catch (e) {
      _snack("Booking failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------- CANCEL (status cancelled + restore slot) -----------------
  Future<void> _cancelBooking({
    required String appointmentId,
    required String dateId,
    required String slot,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Not logged in.");
      return;
    }

    setState(() => _busy = true);

    try {
      final apptRef = _db.collection('appointments').doc(appointmentId);
      final availRef = _db
          .collection('experts')
          .doc(widget.expertId)
          .collection('availability')
          .doc(dateId);

      final dateMidnight = _parseDateId(dateId);

      await _db.runTransaction((tx) async {
        final apptSnap = await tx.get(apptRef);
        if (!apptSnap.exists) throw Exception("Booking not found.");

        final appt = (apptSnap.data() as Map<String, dynamic>?) ?? {};
        if ((appt['userId'] ?? '') != user.uid) {
          throw Exception("You can cancel only your bookings.");
        }

        final status = (appt['status'] ?? 'booked').toString();
        if (status != "booked") {
          throw Exception("This booking is already cancelled.");
        }

        tx.update(apptRef, {
          "status": "cancelled",
          "updatedAt": FieldValue.serverTimestamp(),
        });

        final availSnap = await tx.get(availRef);
        if (!availSnap.exists) {
          tx.set(availRef, {
            "slots": [slot],
            "date": Timestamp.fromDate(dateMidnight), // ✅ important
            "updatedAt": FieldValue.serverTimestamp(),
          });
        } else {
          final data = (availSnap.data() as Map<String, dynamic>?) ?? {};
          final slots = ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();
          if (!slots.contains(slot)) slots.add(slot);
          slots.sort();
          tx.update(availRef, {
            "slots": slots,
            "date": Timestamp.fromDate(dateMidnight), // ✅ ensure
            "updatedAt": FieldValue.serverTimestamp(),
          });
        }
      });

      _snack("Booking cancelled ✅");
    } catch (e) {
      _snack("Cancel failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------- DELETE (hard delete + restore slot if booked) -----------------
  Future<void> _deleteBooking({
    required String appointmentId,
    required String dateId,
    required String slot,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Not logged in.");
      return;
    }

    setState(() => _busy = true);

    try {
      final apptRef = _db.collection('appointments').doc(appointmentId);
      final availRef = _db
          .collection('experts')
          .doc(widget.expertId)
          .collection('availability')
          .doc(dateId);

      final dateMidnight = _parseDateId(dateId);

      await _db.runTransaction((tx) async {
        final apptSnap = await tx.get(apptRef);
        if (!apptSnap.exists) return;

        final appt = (apptSnap.data() as Map<String, dynamic>?) ?? {};
        if ((appt['userId'] ?? '') != user.uid) {
          throw Exception("You can delete only your bookings.");
        }

        final status = (appt['status'] ?? 'booked').toString();

        if (status == "booked") {
          final availSnap = await tx.get(availRef);
          if (!availSnap.exists) {
            tx.set(availRef, {
              "slots": [slot],
              "date": Timestamp.fromDate(dateMidnight),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          } else {
            final data = (availSnap.data() as Map<String, dynamic>?) ?? {};
            final slots = ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();
            if (!slots.contains(slot)) slots.add(slot);
            slots.sort();
            tx.update(availRef, {
              "slots": slots,
              "date": Timestamp.fromDate(dateMidnight),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          }
        }

        tx.delete(apptRef);
      });

      _snack("Booking deleted ✅");
    } catch (e) {
      _snack("Delete failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 30));

    final startId = _dateId(start);
    final endId = _dateId(end);

    final availabilityQuery = _db
        .collection('experts')
        .doc(widget.expertId)
        .collection('availability')
        .orderBy(FieldPath.documentId)
        .startAt([startId])
        .endAt([endId]);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    final myBookingsQuery = (uid == null)
        ? null
        : _db
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .where('expertId', isEqualTo: widget.expertId);

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Expert header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.06),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primary,
                  backgroundImage: widget.expertPhotoUrl.isNotEmpty ? NetworkImage(widget.expertPhotoUrl) : null,
                  child: widget.expertPhotoUrl.isEmpty
                      ? const Icon(Icons.science_outlined, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expertName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.expertSpecialty,
                        style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ----------------- MY BOOKINGS -----------------
          Row(
            children: [
              Text("My bookings", style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),

          if (myBookingsQuery == null)
            _infoBox(cs, "Not logged in.")
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: myBookingsQuery.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _errorBox(cs, "Error loading bookings:\n${snap.error}");
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snap.data?.docs ?? [];

                docs.sort((a, b) {
                  final ad = a.data();
                  final bd = b.data();
                  final at = (ad['date'] is Timestamp) ? (ad['date'] as Timestamp).millisecondsSinceEpoch : 0;
                  final bt = (bd['date'] is Timestamp) ? (bd['date'] as Timestamp).millisecondsSinceEpoch : 0;
                  return at.compareTo(bt);
                });

                if (docs.isEmpty) return _infoBox(cs, "No bookings yet.");

                return Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final status = (data['status'] ?? 'booked').toString();
                    final dateId = (data['dateId'] ?? '').toString();
                    final slot = (data['slot'] ?? '').toString();
                    final isBooked = status == "booked";

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentDetailsScreen(appointmentId: d.id),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: (isBooked ? cs.primary : cs.outlineVariant).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (isBooked ? cs.primary : cs.outlineVariant).withOpacity(0.25),
                                ),
                              ),
                              child: Icon(
                                isBooked ? Icons.event_available : Icons.event_busy,
                                color: isBooked ? cs.primary : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (dateId.isEmpty || slot.isEmpty) ? "Appointment" : "$dateId • $slot",
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: $status",
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap to view details",
                                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (_busy) return;

                                if (v == "cancel") {
                                  await _cancelBooking(
                                    appointmentId: d.id,
                                    dateId: dateId,
                                    slot: slot,
                                  );
                                }
                                if (v == "delete") {
                                  await _deleteBooking(
                                    appointmentId: d.id,
                                    dateId: dateId,
                                    slot: slot,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                if (isBooked) const PopupMenuItem(value: "cancel", child: Text("Cancel booking")),
                                const PopupMenuItem(value: "delete", child: Text("Delete booking")),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

          const SizedBox(height: 18),

          // ----------------- AVAILABILITY -----------------
          Text("Available dates (next 30 days)", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: availabilityQuery.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return _errorBox(cs, "Error loading availability:\n${snap.error}");
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _infoBox(cs, "No availability for the next 30 days.");

              return Column(
                children: docs.map((d) {
                  final dateId = d.id;
                  final data = d.data();
                  final slots = ((data['slots'] ?? []) as List).map((e) => e.toString()).toList()..sort();

                  final selectedDate = _selectedDateId == dateId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(selectedDate ? 1.0 : 0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: selectedDate ? cs.primary : cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(dateId, style: const TextStyle(fontWeight: FontWeight.w900))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: cs.primary.withOpacity(0.25)),
                              ),
                              child: Text(
                                "${slots.length} slots",
                                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: slots.map((s) {
                            final isSelected = selectedDate && _selectedSlot == s;
                            return ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                setState(() {
                                  _selectedDateId = dateId;
                                  _selectedSlot = s;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _busy ? null : _book,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(_busy ? "Please wait..." : "Confirm Booking"),
          ),

          const SizedBox(height: 8),
          Text(
            "Tip: If a time disappears, another user booked it first.",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(ColorScheme cs, String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }

  Widget _errorBox(ColorScheme cs, String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(msg, style: TextStyle(color: cs.onErrorContainer)),
    );
  }

  String _dateId(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  DateTime _parseDateId(String id) {
    final parts = id.split("-");
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(y, m, day);
  }
}
