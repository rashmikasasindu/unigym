import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows all users (role == 'user') and lets instructor view each user's monthly attendance.
class InstructorProgressPage extends StatelessWidget {
  const InstructorProgressPage({super.key});

  static const Color _gradientTop = Color(0xFFD932C6);
  static const Color _gradientBottom = Color(0xFF4A3ED6);

  String _getInitials(String email) {
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress',
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'user')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No members found.',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final uid = docs[index].id;
                          final email =
                              data['email'] as String? ?? 'No email';
                          final displayName =
                              data['displayName'] as String? ??
                                  email.split('@')[0];
                          final regNum =
                              data['registration_number'] as String? ?? '';
                          final initials = _getInitials(email);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF00C97C)
                                        .withValues(alpha: 0.12),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF00C97C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              subtitle: Text(
                                regNum.isNotEmpty
                                    ? '$email  ·  #$regNum'
                                    : email,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12),
                              ),
                              trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF00C97C)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _UserAttendancePage(
                                    uid: uid,
                                    userName: displayName,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}

// ── User Attendance Calendar Page ────────────────────────────────────────────

class _UserAttendancePage extends StatefulWidget {
  final String uid;
  final String userName;

  const _UserAttendancePage(
      {required this.uid, required this.userName});

  @override
  State<_UserAttendancePage> createState() => _UserAttendancePageState();
}

class _UserAttendancePageState extends State<_UserAttendancePage> {
  DateTime _calendarMonth = DateTime.now();
  Set<int> _attendedDays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final days =
        await _fetchAttendedDays(widget.uid, _calendarMonth);
    if (mounted) {
      setState(() {
        _attendedDays = days;
        _isLoading = false;
      });
    }
  }

  Future<Set<int>> _fetchAttendedDays(String uid, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: uid)
        .where('attended', isEqualTo: true)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();
    final days = <int>{};
    for (final doc in snapshot.docs) {
      final date = (doc.data()['date'] as Timestamp?)?.toDate();
      if (date != null) days.add(date.day);
    }
    return days;
  }

  Future<void> _changeMonth(int delta) async {
    final newMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    setState(() {
      _calendarMonth = newMonth;
      _isLoading = true;
    });
    final days = await _fetchAttendedDays(widget.uid, newMonth);
    if (mounted) {
      setState(() {
        _attendedDays = days;
        _isLoading = false;
      });
    }
  }

  String _monthName(int month) {
    const names = [
      '',
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}';
    final daysInMonth = DateUtils.getDaysInMonth(
        _calendarMonth.year, _calendarMonth.month);
    final firstWeekday =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday % 7;
    final now = DateTime.now();
    final isCurrentMonth = _calendarMonth.year == now.year &&
        _calendarMonth.month == now.month;
    final total = _attendedDays.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.userName}\'s Attendance',
          style: const TextStyle(
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
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _statTile(Icons.check_circle_rounded,
                              const Color(0xFF00E676), '$total sessions', 'This Month')),
                          const SizedBox(width: 12),
                          Expanded(child: _statTile(Icons.emoji_events_rounded,
                              const Color(0xFFFFD700),
                              total >= 20 ? '🏆 Hit!' : '${20 - total} left', 'Goal')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Calendar glass card
                      _glassCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => _changeMonth(-1),
                                  icon: const Icon(Icons.chevron_left_rounded,
                                      color: Colors.white, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00E676),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('Attended',
                                            style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => _changeMonth(1),
                                  icon: const Icon(Icons.chevron_right_rounded,
                                      color: Colors.white, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                  .map((d) => SizedBox(
                                        width: 36,
                                        child: Center(
                                          child: Text(d,
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 2,
                                childAspectRatio: 1,
                              ),
                              itemCount: firstWeekday + daysInMonth,
                              itemBuilder: (context, index) {
                                if (index < firstWeekday) {
                                  return const SizedBox.shrink();
                                }
                                final day = index - firstWeekday + 1;
                                final isToday =
                                    isCurrentMonth && day == now.day;
                                final isAttended = _attendedDays.contains(day);

                                Color bgColor = Colors.transparent;
                                Color textColor = Colors.white70;
                                Border? border;
                                BoxShadow? shadow;

                                if (isAttended) {
                                  bgColor = const Color(0xFF00E676);
                                  textColor = Colors.white;
                                  shadow = BoxShadow(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  );
                                } else if (isToday) {
                                  border =
                                      Border.all(color: Colors.white, width: 2);
                                  textColor = Colors.white;
                                }

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                    border: border,
                                    boxShadow:
                                        shadow != null ? [shadow] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: (isAttended || isToday)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _statTile(
      IconData icon, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
