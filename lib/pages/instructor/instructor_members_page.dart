import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Shows all users (role == 'user') and lets instructor view each user's reservations.
class InstructorMembersPage extends StatelessWidget {
  const InstructorMembersPage({super.key});

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
          'My Members',
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
                              Icon(Icons.people_outline,
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
                                    const Color(0xFF4A3ED6)
                                        .withValues(alpha: 0.12),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF4A3ED6),
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
                                  color: Color(0xFF4A3ED6)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _UserReservationsPage(
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

// ── User Reservations Detail Page ────────────────────────────────────────────

class _UserReservationsPage extends StatelessWidget {
  final String uid;
  final String userName;

  const _UserReservationsPage(
      {required this.uid, required this.userName});

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '$userName\'s Reservations',
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
                        .collection('reservations')
                        .where('userId', isEqualTo: uid)
                        .orderBy('date', descending: true)
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
                              Icon(Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No reservations found for $userName.',
                                textAlign: TextAlign.center,
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
                          if (!data.containsKey('date') ||
                              !data.containsKey('timeMinutes')) {
                            return const SizedBox.shrink();
                          }
                          final date =
                              (data['date'] as Timestamp).toDate();
                          final timeMinutes =
                              data['timeMinutes'] as int? ?? 0;
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: statusBg,
                                child: Icon(statusIcon,
                                    color: statusColor, size: 22),
                              ),
                              title: Text(
                                DateFormat('EEEE, MMM d').format(date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              subtitle: Text(
                                '${_formatMinutes(timeMinutes)} – ${_formatMinutes(endMinutes)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
