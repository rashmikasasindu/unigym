import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/reservation_service.dart';
import 'instructor_reservation_page.dart';

class InstructorCheckInPage extends StatefulWidget {
  const InstructorCheckInPage({super.key});

  @override
  State<InstructorCheckInPage> createState() => _InstructorCheckInPageState();
}

class _InstructorCheckInPageState extends State<InstructorCheckInPage> {
  final ReservationService _reservationService = ReservationService();
  bool _isLoading = true;
  String? _reservationId;
  Map<String, dynamic>? _reservationData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTodayReservation();
  }

  Future<void> _loadTodayReservation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await _reservationService.getTodayReservation();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          _reservationId = doc.id;
          _reservationData = doc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _reservationId = null;
          _reservationData = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int timeMinutes) {
    final h = timeMinutes ~/ 60;
    final m = timeMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _bookSlot() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const InstructorReservationPage()),
    );
    _loadTodayReservation();
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('End Session?',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your gym session?\n\nYou will not be able to book another slot today until both sessions (4:00–6:00 PM and 6:00–8:00 PM) have finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _reservationService.endSession(_reservationId!);
      await _loadTodayReservation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending session: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Check-in',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? _buildError()
                  : _reservationId != null
                      ? _buildReservedView()
                      : _buildNoReservationView(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            Text(
              'Could not load your reservation.\n$_error',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _actionButton('Retry', Icons.refresh, _loadTodayReservation),
          ],
        ),
      ),
    );
  }

  Widget _buildNoReservationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded,
                  color: Colors.white, size: 60),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Reservation Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You don't have a gym slot booked for today.\nBook one to get your QR attendance code.",
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _actionButton('Book a Slot', Icons.add_circle_outline, _bookSlot),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCompletedView() {
    final now = DateTime.now();
    final lastSessionEnd =
        DateTime(now.year, now.month, now.day, 20, 0);
    final canRebook = now.isAfter(lastSessionEnd);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 60),
            ),
            const SizedBox(height: 28),
            const Text(
              'Session Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              canRebook
                  ? 'Both sessions have ended. You can book again!'
                  : 'You can book again once both sessions today\n(4:00–6:00 PM and 6:00–8:00 PM) have finished.',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (canRebook)
              _actionButton(
                  'Book a Slot', Icons.add_circle_outline, _bookSlot),
          ],
        ),
      ),
    );
  }

  Widget _buildReservedView() {
    final data = _reservationData!;
    final attended = data['attended'] == true;
    final completed = data['completed'] == true;
    final timeMinutes = data['timeMinutes'] as int? ?? 0;
    final date = (data['date'] as Timestamp?)?.toDate();
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : 'Today';

    if (completed) return _buildSessionCompletedView();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: attended
                        ? Colors.green.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: attended ? Colors.green : Colors.white30,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        attended
                            ? Icons.check_circle_rounded
                            : Icons.pending_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attended
                                  ? 'Attendance Marked ✓'
                                  : 'Reserved — Not Yet Scanned',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dateStr  ·  ${_formatTime(timeMinutes)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Attendance QR Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3ED6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        attended
                            ? 'You have already been checked in.'
                            : 'Show this to the admin to mark attendance.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ColorFiltered(
                        colorFilter: attended
                            ? const ColorFilter.matrix([
                                0.33, 0.33, 0.33, 0, 0,
                                0.33, 0.33, 0.33, 0, 0,
                                0.33, 0.33, 0.33, 0, 0,
                                0, 0, 0, 1, 0,
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.color),
                        child: QrImageView(
                          data: _reservationId!,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      if (attended) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Attendance Confirmed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _loadTodayReservation,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    'Refresh Status',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        if (attended)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  'End Session',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                  shadowColor: Colors.red.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actionButton(
      String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A3ED6),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
    );
  }
}
