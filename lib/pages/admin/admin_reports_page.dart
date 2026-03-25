import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage>
    with SingleTickerProviderStateMixin {
  static const Color _gradientTop = Color(0xFFD932C6);
  static const Color _gradientBottom = Color(0xFF4A3ED6);
  static const int _maxCapacity = 40;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  String _slotStatus(Map<String, dynamic> data) {
    final attended = data['attended'] == true;
    if (attended) return 'Attended';
    final date = (data['date'] as Timestamp).toDate();
    final timeMinutes = data['timeMinutes'] as int? ?? 0;
    final slotEnd = DateTime(
      date.year, date.month, date.day,
      timeMinutes ~/ 60, timeMinutes % 60,
    ).add(const Duration(hours: 2));
    if (slotEnd.isBefore(DateTime.now())) return 'No-show';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: const [
              Tab(text: 'Usage'),
              Tab(text: 'Bookings'),
              Tab(text: 'Instructors'),
            ],
          ),
        ),
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
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: double.infinity,
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
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                final reservations = docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _UsageTab(
                      reservations: reservations,
                      maxCapacity: _maxCapacity,
                      formatMinutes: _formatMinutes,
                      slotStatus: _slotStatus,
                    ),
                    _BookingsTab(
                      reservations: reservations,
                      slotStatus: _slotStatus,
                      formatMinutes: _formatMinutes,
                    ),
                    _InstructorsTab(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 1 – Usage Report
// ─────────────────────────────────────────────────────────────────────────────

class _UsageTab extends StatelessWidget {
  final List<Map<String, dynamic>> reservations;
  final int maxCapacity;
  final String Function(int) formatMinutes;
  final String Function(Map<String, dynamic>) slotStatus;

  const _UsageTab({
    required this.reservations,
    required this.maxCapacity,
    required this.formatMinutes,
    required this.slotStatus,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Total bookings per day (last 7 days)
    final Map<String, int> perDay = {};
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      perDay[DateFormat('EEE d').format(d)] = 0;
    }
    for (final r in reservations) {
      final date = (r['date'] as Timestamp).toDate();
      final key = DateFormat('EEE d').format(date);
      if (perDay.containsKey(key)) {
        perDay[key] = (perDay[key] ?? 0) + 1;
      }
    }

    // This week total
    int weekTotal = 0;
    for (final r in reservations) {
      final date = (r['date'] as Timestamp).toDate();
      if (!date.isBefore(weekStart)) weekTotal++;
    }

    // Peak hours (by timeMinutes slot)
    final Map<int, int> slotCount = {};
    for (final r in reservations) {
      final t = r['timeMinutes'] as int? ?? 0;
      slotCount[t] = (slotCount[t] ?? 0) + 1;
    }
    int? peakSlot;
    int peakCount = 0;
    slotCount.forEach((slot, count) {
      if (count > peakCount) {
        peakCount = count;
        peakSlot = slot;
      }
    });

    // Average occupancy (attended / maxCapacity per slot across past days)
    final attended =
        reservations.where((r) => r['attended'] == true).length;
    final totalSlots =
        reservations.where((r) => slotStatus(r) != 'Upcoming').length;
    final avgOccupancy = totalSlots == 0
        ? 0.0
        : (attended / totalSlots * 100).clamp(0.0, 100.0);

    final maxBar =
        perDay.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _InfoCard(
                label: 'This Week',
                value: weekTotal.toString(),
                sub: 'total bookings',
                color: const Color(0xFF4A3ED6),
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 12),
              _InfoCard(
                label: 'Avg Occupancy',
                value: '${avgOccupancy.toStringAsFixed(0)}%',
                sub: 'of capacity filled',
                color: const Color(0xFFD932C6),
                icon: Icons.people_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoCard(
                label: 'Peak Slot',
                value: peakSlot != null
                    ? formatMinutes(peakSlot!)
                    : '–',
                sub: peakSlot != null ? '$peakCount bookings' : 'No data',
                color: const Color(0xFFFF9800),
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(width: 12),
              _InfoCard(
                label: 'Total Booked',
                value: reservations.length.toString(),
                sub: 'all time',
                color: const Color(0xFF00C97C),
                icon: Icons.event_available_rounded,
              ),
            ],
          ),

          const SizedBox(height: 28),
          _sectionTitle('Bookings – Last 7 Days'),
          const SizedBox(height: 16),

          // Bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: perDay.entries.map((entry) {
                final barH = maxBar == 0
                    ? 0.0
                    : (entry.value / maxBar * 100).clamp(8.0, 100.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFF4A3ED6), Color(0xFFD932C6)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),
          _sectionTitle('Slot Breakdown'),
          const SizedBox(height: 12),

          // Slot occupancy per time
          ...slotCount.entries.map((entry) {
            final fill = (entry.value / maxCapacity).clamp(0.0, 1.0);
            return _ProgressRow(
              label: formatMinutes(entry.key),
              count: entry.value,
              max: maxCapacity,
              fill: fill,
              color: fill > 0.75
                  ? Colors.red.shade400
                  : fill > 0.4
                      ? Colors.orange.shade400
                      : const Color(0xFF00C97C),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 2 – Booking Report
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsTab extends StatelessWidget {
  final List<Map<String, dynamic>> reservations;
  final String Function(Map<String, dynamic>) slotStatus;
  final String Function(int) formatMinutes;

  const _BookingsTab({
    required this.reservations,
    required this.slotStatus,
    required this.formatMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final attended =
        reservations.where((r) => r['attended'] == true).toList();
    // Note: cancellations are hard-deletes in Firestore so they are not tracked here.
    final noshow = reservations
        .where((r) => slotStatus(r) == 'No-show')
        .toList();
    final upcoming = reservations
        .where((r) => slotStatus(r) == 'Upcoming')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              _InfoCard(
                label: 'Completed',
                value: attended.length.toString(),
                sub: 'attended',
                color: const Color(0xFF00C97C),
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 12),
              _InfoCard(
                label: 'No-shows',
                value: noshow.length.toString(),
                sub: 'missed slot',
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoCard(
                label: 'Upcoming',
                value: upcoming.length.toString(),
                sub: 'active bookings',
                color: const Color(0xFF4A3ED6),
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(width: 12),
              _InfoCard(
                label: 'Cancelled',
                value: '–',
                sub: 'not tracked',
                color: Colors.red.shade400,
                icon: Icons.cancel_rounded,
              ),
            ],
          ),

          const SizedBox(height: 28),
          _sectionTitle('Completed Bookings'),
          const SizedBox(height: 12),
          if (attended.isEmpty)
            _emptyState('No completed bookings yet.')
          else
            ...attended.map((r) => _BookingRow(
                  data: r,
                  status: 'Attended',
                  formatMinutes: formatMinutes,
                  statusColor: Colors.green.shade700,
                  statusBg: const Color(0xFFE8F5E9),
                  icon: Icons.check_circle_rounded,
                )),

          const SizedBox(height: 20),
          _sectionTitle('No-shows'),
          const SizedBox(height: 12),
          if (noshow.isEmpty)
            _emptyState('No missed bookings.')
          else
            ...noshow.map((r) => _BookingRow(
                  data: r,
                  status: 'No-show',
                  formatMinutes: formatMinutes,
                  statusColor: Colors.orange.shade700,
                  statusBg: Colors.orange.shade50,
                  icon: Icons.warning_amber_rounded,
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 3 – Instructor Report
// ─────────────────────────────────────────────────────────────────────────────

class _InstructorsTab extends StatelessWidget {
  const _InstructorsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Instructor')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final instructors = snap.data?.docs ?? [];

        if (instructors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No instructors found.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Users with role "Instructor" will appear here.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          itemCount: instructors.length,
          itemBuilder: (context, index) {
            final data =
                instructors[index].data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? 'Unknown';
            final email = data['email'] as String? ?? '';
            final contact =
                data['contact_number'] as String? ?? '';
            final gender = data['gender'] as String? ?? '';
            final initials = name
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                .join();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFF0FA),
                  child: Text(
                    initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD932C6),
                        fontSize: 16),
                  ),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    if (contact.isNotEmpty)
                      Text(
                          '📞 $contact${gender.isNotEmpty ? '  ·  $gender' : ''}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Instructor',
                    style: TextStyle(
                      color: Color(0xFFD932C6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final double fill;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.count,
    required this.max,
    required this.fill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                '$count / $max',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  final String Function(int) formatMinutes;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;

  const _BookingRow({
    required this.data,
    required this.status,
    required this.formatMinutes,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final date = (data['date'] as Timestamp).toDate();
    final timeMinutes = data['timeMinutes'] as int? ?? 0;
    final endMinutes = timeMinutes + 120;
    final userName = data['userName'] as String? ?? 'Unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: statusBg,
          child: Icon(icon, color: statusColor, size: 18),
        ),
        title: Text(userName,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          '${DateFormat('MMM d').format(date)}  ·  ${formatMinutes(timeMinutes)} – ${formatMinutes(endMinutes)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );
}

Widget _emptyState(String msg) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    ),
  );
}
