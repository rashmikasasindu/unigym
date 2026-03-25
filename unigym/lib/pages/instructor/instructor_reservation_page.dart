import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';

/// Reservation page for instructors.
/// Rules: max 1 slot per day, can book across up to 3 different upcoming days
/// (not 3 consecutive — just cannot have 2 slots on the SAME day).
class InstructorReservationPage extends StatefulWidget {
  const InstructorReservationPage({super.key});

  @override
  State<InstructorReservationPage> createState() =>
      _InstructorReservationPageState();
}

class _InstructorReservationPageState
    extends State<InstructorReservationPage> {
  final ReservationService _service = ReservationService();

  DateTime? _selectedDate;
  int? _selectedTimeMinutes;

  static const int _maxCapacity = 40;

  static const List<Map<String, dynamic>> _slots = [
    {'label': '4:00 PM – 6:00 PM', 'minutes': 960},
    {'label': '6:00 PM – 8:00 PM', 'minutes': 1080},
  ];

  static const Color _gradientTop = Color(0xFFD932C6);
  static const Color _gradientBottom = Color(0xFF4A3ED6);
  static const Color _accent = Color(0xFF4A3ED6);

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(3, (i) => DateTime(now.year, now.month, now.day + i));
  }

  String _getDayLabel(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return DateFormat('E, MMM d').format(_days[index]);
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _submitReservation() async {
    if (_selectedDate == null || _selectedTimeMinutes == null) return;
    try {
      await _service.createReservation(
        date: _selectedDate!,
        timeMinutes: _selectedTimeMinutes!,
      );
      if (!mounted) return;
      setState(() {
        _selectedDate = null;
        _selectedTimeMinutes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reservation confirmed! 🎉'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelReservation(String docId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Reservation'),
        content: Text('Cancel your booking for $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.cancelReservation(docId);
    }
  }

  Future<void> _rescheduleReservation(String docId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Slot'),
        content: Text(
          'This will delete your current booking ($label) so you can choose a new slot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.cancelReservation(docId);
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
          'Reserve a Slot',
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
            colors: [_gradientTop, _gradientBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  // Stream: instructor's existing bookings (by day)
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _service.getUserReservations(),
                    builder: (context, mySnap) {
                      // Compute set of days instructor already booked
                      final Set<String> bookedDays = {};
                      if (mySnap.hasData) {
                        for (final doc in mySnap.data!.docs) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final date =
                              (data['date'] as Timestamp?)?.toDate();
                          final attended = data['attended'] == true;
                          final now = DateTime.now();
                          if (date != null) {
                            final slotMin =
                                data['timeMinutes'] as int? ?? 0;
                            final slotEnd = DateTime(date.year, date.month,
                                    date.day, slotMin ~/ 60, slotMin % 60)
                                .add(const Duration(hours: 2));
                            // Only count future/active reservations for blocking
                            if (!attended && slotEnd.isAfter(now)) {
                              bookedDays.add(
                                  '${date.year}-${date.month}-${date.day}');
                            }
                          }
                        }
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Instructor note
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 18, color: _accent),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'As an instructor, you can book up to one slot per day across any of the 3 upcoming days.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Availability grid ───────────────────────
                            _sectionTitle('Available Slots'),
                            const SizedBox(height: 12),
                            _buildAvailabilityTable(
                                bookedDays: bookedDays),
                            const SizedBox(height: 24),

                            // ── Confirm button ───────────────────────────
                            if (_selectedDate != null &&
                                _selectedTimeMinutes != null) ...[
                              _buildConfirmSection(),
                              const SizedBox(height: 24),
                            ],

                            // ── My reservations ──────────────────────────
                            _sectionTitle('My Reservations'),
                            const SizedBox(height: 12),
                            _buildMyReservations(mySnap),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityTable({required Set<String> bookedDays}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getAllConfirmedReservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _tableHeaderRow(),
              const Divider(height: 1),
              ..._slots.asMap().entries.map((entry) {
                final rowIdx = entry.key;
                final slot = entry.value;
                return Column(
                  children: [
                    if (rowIdx > 0) const Divider(height: 1),
                    _tableSlotRow(
                      slot: slot,
                      allDocs: allDocs,
                      bookedDays: bookedDays,
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 120),
          ..._days.asMap().entries.map((e) => Expanded(
                child: Center(
                  child: Text(
                    _getDayLabel(e.key),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF4A3ED6),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _tableSlotRow({
    required Map<String, dynamic> slot,
    required List<QueryDocumentSnapshot> allDocs,
    required Set<String> bookedDays,
  }) {
    final slotMinutes = slot['minutes'] as int;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              slot['label'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ..._days.map((day) {
            // Count bookings for this day+slot
            int booked = 0;
            for (final doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              if (!data.containsKey('date') ||
                  !data.containsKey('timeMinutes')) continue;
              final docDate = (data['date'] as Timestamp).toDate();
              final docMin = data['timeMinutes'] as int? ?? 0;
              if (docDate.year == day.year &&
                  docDate.month == day.month &&
                  docDate.day == day.day &&
                  docMin == slotMinutes) {
                booked++;
              }
            }

            final left = (_maxCapacity - booked).clamp(0, _maxCapacity);

            // Instructor blocked if already booked this day
            final dayKey = '${day.year}-${day.month}-${day.day}';
            final isDayBooked = bookedDays.contains(dayKey);

            final now = DateTime.now();
            final slotEnd = DateTime(
              day.year,
              day.month,
              day.day,
              slotMinutes ~/ 60,
              slotMinutes % 60,
            ).add(const Duration(hours: 2));
            final isPast = slotEnd.isBefore(now);

            final isSelected = _selectedDate == day &&
                _selectedTimeMinutes == slotMinutes;
            final isAvailable =
                left > 0 && !isDayBooked && !isPast;

            return Expanded(
              child: GestureDetector(
                onTap: isAvailable
                    ? () => setState(() {
                          _selectedDate = day;
                          _selectedTimeMinutes = slotMinutes;
                        })
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isPast
                        ? Colors.grey.shade100
                        : isDayBooked
                            ? Colors.purple.shade50
                            : isSelected
                                ? const Color(0xFF4A3ED6)
                                    .withValues(alpha: 0.12)
                                : left == 0
                                    ? Colors.red.shade50
                                    : const Color(0xFFE8F5E9),
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFF4A3ED6), width: 2)
                        : isDayBooked && !isPast
                            ? Border.all(
                                color: Colors.purple.shade200, width: 1)
                            : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPast
                            ? '–'
                            : isDayBooked
                                ? '✓'
                                : left == 0
                                    ? 'Full'
                                    : '$left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isPast
                              ? Colors.grey.shade400
                              : isDayBooked
                                  ? Colors.purple.shade400
                                  : left == 0
                                      ? Colors.red
                                      : const Color(0xFF4CAF50),
                        ),
                      ),
                      if (!isPast && !isDayBooked && left > 0)
                        Text(
                          'left',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500),
                        ),
                      if (!isPast && isDayBooked)
                        Text(
                          'booked',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.purple.shade400),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildConfirmSection() {
    final dateStr = DateFormat('EEEE, MMM d').format(_selectedDate!);
    final timeStr = _formatMinutes(_selectedTimeMinutes!);
    final endStr = _formatMinutes(_selectedTimeMinutes! + 120);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF4A3ED6).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3ED6).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  color: Color(0xFF4A3ED6), size: 22),
              const SizedBox(width: 10),
              const Text(
                'Confirm your slot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF4A3ED6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$dateStr\n$timeStr – $endStr',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A3ED6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _submitReservation,
              child: const Text('Confirm Reservation',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReservations(AsyncSnapshot<QuerySnapshot> mySnap) {
    if (mySnap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!mySnap.hasData || mySnap.data!.docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'No reservations yet.\nBook a slot above!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: mySnap.data!.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('date') || !data.containsKey('timeMinutes')) {
          return const SizedBox.shrink();
        }

        final date = (data['date'] as Timestamp).toDate();
        final timeMinutes = data['timeMinutes'] as int? ?? 0;
        final endMinutes = timeMinutes + 120;
        final attended = data['attended'] == true;

        final slotEnd = DateTime(
          date.year,
          date.month,
          date.day,
          timeMinutes ~/ 60,
          timeMinutes % 60,
        ).add(const Duration(hours: 2));
        final isPast = slotEnd.isBefore(DateTime.now());

        String statusLabel;
        Color statusColor;
        Color statusBg;
        IconData statusIcon;

        if (attended) {
          statusLabel = 'Attended';
          statusColor = Colors.green.shade700;
          statusBg = const Color(0xFFE8F5E9);
          statusIcon = Icons.check_circle_rounded;
        } else if (isPast) {
          statusLabel = 'Missed';
          statusColor = Colors.orange.shade700;
          statusBg = Colors.orange.shade50;
          statusIcon = Icons.warning_amber_rounded;
        } else {
          statusLabel = 'Upcoming';
          statusColor = const Color(0xFF4A3ED6);
          statusBg = const Color(0xFFEDE7F6);
          statusIcon = Icons.access_time_rounded;
        }

        final canModify = !attended && !isPast;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: statusBg,
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            title: Text(
              DateFormat('EEEE, MMM d').format(date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_formatMinutes(timeMinutes)} – ${_formatMinutes(endMinutes)}',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            trailing: canModify
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statusBadge(statusLabel, statusColor, statusBg),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          final slotLabel =
                              '${_formatMinutes(timeMinutes)} – ${_formatMinutes(endMinutes)} on ${DateFormat('MMM d').format(date)}';
                          if (value == 'cancel') {
                            _cancelReservation(doc.id, slotLabel);
                          } else if (value == 'change') {
                            _rescheduleReservation(doc.id, slotLabel);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'change',
                            child: Row(children: [
                              Icon(Icons.edit_calendar_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Change Slot'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  )
                : _statusBadge(statusLabel, statusColor, statusBg),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A3ED6),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
