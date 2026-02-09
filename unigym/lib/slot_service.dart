import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles gym time slot reservations in Firestore.
///
/// Expected Firestore structure:
/// - gyms (collection)
///   - {gymId} (document)
///     - slots (subcollection)
///       - {slotId} (document)
///         - startTime: Timestamp/string
///         - endTime: Timestamp/string
///         - maxCapacity: int
///         - currentReservations: int
///         - reservations (subcollection, optional but recommended)
///           - {userId} (document)
///             - userId: string
///             - createdAt: Timestamp
class SlotService {
  SlotService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Try to reserve a time slot for the currently signed-in user.
  ///
  /// Returns `true` if the reservation was created, or `false` if the slot
  /// is already full (i.e. currentReservations >= maxCapacity).
  Future<bool> reserveSlot({
    required String gymId,
    required String slotId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final slotRef = _db
        .collection('gyms')
        .doc(gymId)
        .collection('slots')
        .doc(slotId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(slotRef);

      if (!snapshot.exists) {
        throw Exception('Slot not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final int maxCapacity = (data['maxCapacity'] ?? 0) as int;
      final int currentReservations =
          (data['currentReservations'] ?? 0) as int;

      // Slot is already at or above capacity.
      if (currentReservations >= maxCapacity) {
        return false;
      }

      // Update counters.
      transaction.update(slotRef, {
        'currentReservations': currentReservations + 1,
      });

      // Record the reservation for this user (one per user per slot).
      final reservationRef =
          slotRef.collection('reservations').doc(user.uid);
      transaction.set(reservationRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  /// Cancel a reservation made by the current user and free a spot.
  Future<void> cancelReservation({
    required String gymId,
    required String slotId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final slotRef = _db
        .collection('gyms')
        .doc(gymId)
        .collection('slots')
        .doc(slotId);
    final reservationRef =
        slotRef.collection('reservations').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final slotSnap = await transaction.get(slotRef);
      if (!slotSnap.exists) {
        return;
      }

      final data = slotSnap.data() as Map<String, dynamic>;
      final int currentReservations =
          (data['currentReservations'] ?? 0) as int;

      final int newCount =
          currentReservations > 0 ? currentReservations - 1 : 0;

      transaction.update(slotRef, {
        'currentReservations': newCount,
      });

      transaction.delete(reservationRef);
    });
  }
}

