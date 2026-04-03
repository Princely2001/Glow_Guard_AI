import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'appointment_details_screen.dart';
import 'payment_gateway_screen.dart';

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
  String? _selectedDateId;
  String? _selectedSlot;
  bool _busy = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- DATE / TIME HELPERS ----------------
  String _dateId(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  DateTime _parseDateId(String id) {
    final parts = id.split("-");
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(y, m, day);
  }

  bool _isSlotInPast(String dateId, String slot) {
    final now = DateTime.now();
    final parts = dateId.split("-");
    if (parts.length != 3) return false;

    final y = int.tryParse(parts[0]) ?? now.year;
    final m = int.tryParse(parts[1]) ?? now.month;
    final d = int.tryParse(parts[2]) ?? now.day;

    if (y < now.year) return true;
    if (y == now.year && m < now.month) return true;
    if (y == now.year && m == now.month && d < now.day) return true;

    if (y > now.year ||
        (y == now.year && m > now.month) ||
        (y == now.year && m == now.month && d > now.day)) {
      return false;
    }

    int hour = 0;
    int minute = 0;
    try {
      final cleanSlot = slot.trim().toUpperCase();
      final isPM = cleanSlot.contains("PM");
      final isAM = cleanSlot.contains("AM");
      final timePart = cleanSlot.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final tParts = timePart.split(":");

      hour = int.parse(tParts[0]);
      if (tParts.length > 1) {
        minute = int.parse(tParts[1]);
      }
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      final slotTime = DateTime(y, m, d, hour, minute);
      return slotTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  // ---------------- STATUS HELPERS ----------------
  bool _isCompleted(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final chemicalStatus =
    (data['chemicalStatus'] ?? '').toString().trim().toLowerCase();
    final testStatus =
    (data['testStatus'] ?? '').toString().trim().toLowerCase();

    return status == 'completed' ||
        status == 'done' ||
        status == 'test_completed' ||
        chemicalStatus == 'completed' ||
        chemicalStatus == 'done' ||
        testStatus == 'completed' ||
        testStatus == 'done' ||
        data['chemicalTestDone'] == true ||
        data['resultSaved'] == true;
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected';
  }

  bool _isBooked(Map<String, dynamic> data) {
    return !_isCompleted(data) && !_isCancelled(data);
  }

  String _displayStatus(Map<String, dynamic> data) {
    if (_isCompleted(data)) return 'completed';
    if (_isCancelled(data)) return 'cancelled';
    return (data['status'] ?? 'booked').toString();
  }

  Color _statusColor(BuildContext context, Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;
    if (_isCompleted(data)) return Colors.green;
    if (_isCancelled(data)) return cs.error;
    return cs.primary;
  }

  IconData _statusIcon(Map<String, dynamic> data) {
    if (_isCompleted(data)) return Icons.check_circle_outline;
    if (_isCancelled(data)) return Icons.event_busy;
    return Icons.event_available;
  }

  // ---------------- INITIATE PAYMENT & BOOKING ----------------
  Future<void> _initiateBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Not logged in.");
      return;
    }
    if (_selectedDateId == null || _selectedSlot == null) {
      _snack("Select date and time first.");
      return;
    }

    if (_isSlotInPast(_selectedDateId!, _selectedSlot!)) {
      _snack("This time slot has already passed.");
      return;
    }

    final bool? paymentSuccess = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayScreen(
          amount: 1500.0,
          expertName: widget.expertName,
        ),
      ),
    );

    if (paymentSuccess == true) {
      await _book();
    } else {
      _snack("Payment was cancelled or failed.");
    }
  }

  Future<void> _book() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
        final slots =
        ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();

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
            "date": Timestamp.fromDate(dateMidnight),
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
          "paymentStatus": "paid",
          "chemicalStatus": "pending",
          "testStatus": "pending",
          "chemicalTestDone": false,
          "resultSaved": false,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      _snack("Appointment booked ✅");

      setState(() {
        _selectedSlot = null;
      });
    } catch (e) {
      _snack("Booking failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------- CANCEL ----------------
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

        if (!_isBooked(appt)) {
          throw Exception("Only active booked appointments can be cancelled.");
        }

        tx.update(apptRef, {
          "status": "cancelled",
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (!_isSlotInPast(dateId, slot)) {
          final availSnap = await tx.get(availRef);
          if (!availSnap.exists) {
            tx.set(availRef, {
              "slots": [slot],
              "date": Timestamp.fromDate(dateMidnight),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          } else {
            final data = (availSnap.data() as Map<String, dynamic>?) ?? {};
            final slots =
            ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();
            if (!slots.contains(slot)) slots.add(slot);
            slots.sort();
            tx.update(availRef, {
              "slots": slots,
              "date": Timestamp.fromDate(dateMidnight),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          }
        }
      });

      _snack("Booking cancelled ✅");
    } catch (e) {
      _snack("Cancel failed: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------- DELETE ----------------
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

        if (_isBooked(appt) && !_isSlotInPast(dateId, slot)) {
          final availSnap = await tx.get(availRef);
          if (!availSnap.exists) {
            tx.set(availRef, {
              "slots": [slot],
              "date": Timestamp.fromDate(dateMidnight),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          } else {
            final data = (availSnap.data() as Map<String, dynamic>?) ?? {};
            final slots =
            ((data['slots'] ?? []) as List).map((e) => e.toString()).toList();
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

  // ---------------- UI ----------------
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
              ),
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
                  backgroundImage: widget.expertPhotoUrl.isNotEmpty
                      ? NetworkImage(widget.expertPhotoUrl)
                      : null,
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.expertSpecialty,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text("My bookings", style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (myBookingsQuery == null)
            _infoBox(cs, "Not logged in.")
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: myBookingsQuery.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _errorBox(
                    cs,
                    "Error loading bookings:\n${snap.error}",
                  );
                }
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
                  final at = (ad['date'] is Timestamp)
                      ? (ad['date'] as Timestamp).millisecondsSinceEpoch
                      : 0;
                  final bt = (bd['date'] is Timestamp)
                      ? (bd['date'] as Timestamp).millisecondsSinceEpoch
                      : 0;
                  return at.compareTo(bt);
                });

                if (docs.isEmpty) return _infoBox(cs, "No bookings yet.");

                return Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final dateId = (data['dateId'] ?? '').toString();
                    final slot = (data['slot'] ?? '').toString();

                    final isBooked = _isBooked(data);
                    final shownStatus = _displayStatus(data);
                    final statusColor = _statusColor(context, data);
                    final icon = _statusIcon(data);

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AppointmentDetailsScreen(appointmentId: d.id),
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
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.25),
                                ),
                              ),
                              child: Icon(icon, color: statusColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (dateId.isEmpty || slot.isEmpty)
                                        ? "Appointment"
                                        : "$dateId • $slot",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: $shownStatus",
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  if (_isCompleted(data))
                                    Text(
                                      "Chemical test completed",
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  else
                                    Text(
                                      "Tap to view details",
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                if (isBooked)
                                  const PopupMenuItem(
                                    value: "cancel",
                                    child: Text("Cancel booking"),
                                  ),
                                const PopupMenuItem(
                                  value: "delete",
                                  child: Text("Delete booking"),
                                ),
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

          Text(
            "Available dates (next 30 days)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: availabilityQuery.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return _errorBox(
                  cs,
                  "Error loading availability:\n${snap.error}",
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data?.docs ?? [];
              List<Widget> availableDatesWidgets = [];

              for (var d in docs) {
                final dateId = d.id;
                final data = d.data();
                var slots = ((data['slots'] ?? []) as List)
                    .map((e) => e.toString())
                    .toList()
                  ..sort();

                slots = slots.where((s) => !_isSlotInPast(dateId, s)).toList();

                if (slots.isEmpty) continue;

                final selectedDate = _selectedDateId == dateId;

                availableDatesWidgets.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest
                          .withOpacity(selectedDate ? 1.0 : 0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selectedDate ? cs.primary : cs.outlineVariant,
                      ),
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
                            Expanded(
                              child: Text(
                                dateId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                "${slots.length} slots",
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: slots.map((s) {
                            final isSelected =
                                selectedDate && _selectedSlot == s;
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
                  ),
                );
              }

              if (availableDatesWidgets.isEmpty) {
                return _infoBox(cs, "No availability for the next 30 days.");
              }

              return Column(children: availableDatesWidgets);
            },
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _busy ? null : _initiateBooking,
            icon: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.payment),
            label: Text(_busy ? "Please wait..." : "Pay & Confirm Booking"),
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
}