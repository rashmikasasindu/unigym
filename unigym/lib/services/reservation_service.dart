import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> createReservation({
    required DateTime date,
    required int timeMinutes, // minutes from midnight, e.g. 960 = 4:00 PM
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final dateOnly = DateTime(date.year, date.month, date.day);

    await _firestore.collection('reservations').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'date': Timestamp.fromDate(dateOnly),
      'timeMinutes': timeMinutes,
      'attended': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Cancel / Delete ─────────────────────────────────────────────────────────

  Future<void> cancelReservation(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).delete();
  }

  // ── Read: all reservations for current user (real-time) ────────────────────

  Stream<QuerySnapshot> getUserReservations() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ── Read: active reservation for current user (real-time) ──────────────────
  //
  // A reservation is "active" if:
  //   • it belongs to this user
  //   • the slot end time  (date + timeMinutes + 120 min) is in the future
  //   • attended == false
  //
  // "active" also covers same-day blocking: once you have any reservation
  // for today (past or future slot), you cannot book another one today
  // until that slot has fully elapsed without attendance OR attendance marked.
  //
  // We return the document snapshot so the caller can read data + id.

  Stream<DocumentSnapshot?> getActiveReservationStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('attended', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final timeMinutes = data['timeMinutes'] as int? ?? 0;

        // Build the slot end DateTime
        final slotEnd = DateTime(
          date.year,
          date.month,
          date.day,
          timeMinutes ~/ 60,
          timeMinutes % 60,
        ).add(const Duration(hours: 2));

        if (slotEnd.isAfter(now)) {
          return doc; // This is the active one
        }
      }
      return null; // No active reservation
    });
  }

  // ── Read: count confirmed (non-attended, still future) slots per slot ───────
  // Used by the availability table — returns a stream of all non-attended docs.

  Stream<QuerySnapshot> getAllConfirmedReservations() {
    // Include ALL reservations (attended or not) so that the slot count
    // is NOT restored when someone scans their QR code. A slot is only
    // freed when a reservation is cancelled (document deleted).
    return _firestore
        .collection('reservations')
        .snapshots();
  }

  // ── Mark Attendance ─────────────────────────────────────────────────────────

  Future<void> markAttendance(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).update({
      'attended': true,
      'attendedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── End Session ─────────────────────────────────────────────────────────────
  // Marks a reservation as completed (session ended by user).

  Future<void> endSession(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Check if both daily sessions are ended ──────────────────────────────────
  // The two fixed slots are 4:00 PM–6:00 PM (240 min) and 6:00 PM–8:00 PM (360 min).
  // A session is considered "ended" when its current time is past the slot end
  // time OR the user explicitly ended it (completed == true).
  // Returns true when the user can freely book again today.

  Future<bool> areBothSessionsEndedToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // The last session ends at 8:00 PM = 20*60 = 1200 minutes → 20:00
    final lastSessionEnd = DateTime(today.year, today.month, today.day, 20, 0);

    // If current time is past 8:00 PM both sessions have naturally concluded.
    if (now.isAfter(lastSessionEnd)) return true;

    // Otherwise check if the user has a completed reservation for today.
    // If they have completed their session we allow rebooking only after the
    // second slot naturally ends (8 PM). So we return false here — the user
    // must wait until 8 PM.
    return false;
  }

  // ── Check if user has any reservation today (including completed) ───────────

  Future<bool> hasAnyReservationToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    return snap.docs.isNotEmpty;
  }

  // ── Get by ID (for admin scan) ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getReservationById(String reservationId) async {
    try {
      final doc =
          await _firestore.collection('reservations').doc(reservationId).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) print('Error fetching reservation: $e');
      return null;
    }
  }

  // ── Legacy helpers kept for CheckIn_page compatibility ─────────────────────

  Future<QuerySnapshot> getTodayReservation() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .limit(1)
        .get();
  }
}
