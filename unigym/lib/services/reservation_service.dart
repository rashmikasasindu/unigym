import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createReservation({
    required DateTime date,
    required int timeMinutes, // minutes from midnight
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Create a date-only timestamp for easier querying
    final dateOnly = DateTime(date.year, date.month, date.day);

    final reservationData = {
      'userId': user.uid,
      'userName': user.displayName ?? 'User', // Fallback
      'date': Timestamp.fromDate(dateOnly),
      'timeMinutes': timeMinutes,
      'attended': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('reservations').add(reservationData);
  }

  Stream<QuerySnapshot> getUserReservations() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }
  
  // Get today's reservation for the current user
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

  Future<void> markAttendance(String reservationId) async {
    await _firestore.collection('reservations').doc(reservationId).update({
      'attended': true,
      'attendedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore.collection('reservations').doc(reservationId).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching reservation: $e');
      }
      return null;
    }
  }
}
