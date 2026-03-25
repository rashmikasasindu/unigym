import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminViewReservationPage extends StatefulWidget {
  const AdminViewReservationPage({super.key});

  @override
  State<AdminViewReservationPage> createState() =>
      _AdminViewReservationPageState();
}

class _AdminViewReservationPageState
    extends State<AdminViewReservationPage> with SingleTickerProviderStateMixin {
  static const Color _gradientTop = Color(0xFFD932C6);
  static const Color _gradientBottom = Color(0xFF4A3ED6);

  late TabController _tabController;
  String _searchQuery = '';

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

  Future<void> _cancelReservation(String docId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Reservation'),
          ],
        ),
        content: Text('Cancel "$label"?\nThis action cannot be undone.'),
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
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reservation cancelled'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Filter based on status tab and search
  List<QueryDocumentSnapshot> _filterDocs(
      List<QueryDocumentSnapshot> docs, String tab) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _slotStatus(data);
      final name = (data['userName'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchSearch = q.isEmpty || name.contains(q);
      final matchTab = tab == 'All' ||
          (tab == 'Upcoming' && status == 'Upcoming') ||
          (tab == 'Attended' && status == 'Attended') ||
          (tab == 'No-show' && status == 'No-show');

      return matchSearch && matchTab;
    }).toList()
      ..sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = (aData['date'] as Timestamp).toDate();
        final bDate = (bData['date'] as Timestamp).toDate();
        return bDate.compareTo(aDate); // newest first
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Reservations',
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
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
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.search_rounded, color: Colors.white70),
                      hintText: 'Search by member name…',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Content
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reservations')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allDocs = snap.data?.docs ?? [];

                      // Stats
                      final upcoming = allDocs
                          .where((d) =>
                              _slotStatus(d.data() as Map<String, dynamic>) ==
                              'Upcoming')
                          .length;
                      final attended = allDocs
                          .where((d) =>
                              _slotStatus(d.data() as Map<String, dynamic>) ==
                              'Attended')
                          .length;
                      final noshow = allDocs
                          .where((d) =>
                              _slotStatus(d.data() as Map<String, dynamic>) ==
                              'No-show')
                          .length;

                      return Column(
                        children: [
                          // Stats row
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Row(
                              children: [
                                _statChip('Total', allDocs.length.toString(),
                                    const Color(0xFF4A3ED6)),
                                const SizedBox(width: 8),
                                _statChip('Upcoming', upcoming.toString(),
                                    const Color(0xFF00C97C)),
                                const SizedBox(width: 8),
                                _statChip('Attended', attended.toString(),
                                    Colors.blue.shade600),
                                const SizedBox(width: 8),
                                _statChip(
                                    'No-show', noshow.toString(), Colors.orange),
                              ],
                            ),
                          ),
                          // Tab pages
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildList(_filterDocs(allDocs, 'All')),
                                _buildList(
                                    _filterDocs(allDocs, 'Upcoming')),
                                _buildList(
                                    _filterDocs(allDocs, 'No-show')),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'No reservations found.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _ReservationCard(
          docId: doc.id,
          data: data,
          status: _slotStatus(data),
          formatMinutes: _formatMinutes,
          onCancel: (String label) =>
              _cancelReservation(doc.id, label),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(
              label,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual reservation card ───────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String status;
  final String Function(int) formatMinutes;
  final void Function(String label) onCancel;

  const _ReservationCard({
    required this.docId,
    required this.data,
    required this.status,
    required this.formatMinutes,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final date = (data['date'] as Timestamp).toDate();
    final timeMinutes = data['timeMinutes'] as int? ?? 0;
    final endMinutes = timeMinutes + 120;
    final userName = data['userName'] as String? ?? 'Unknown';
    final dateStr = DateFormat('EEE, MMM d').format(date);
    final slotLabel =
        '$dateStr  ${formatMinutes(timeMinutes)} – ${formatMinutes(endMinutes)}';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'Attended':
        statusColor = Colors.green.shade700;
        statusBg = const Color(0xFFE8F5E9);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'No-show':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = const Color(0xFF4A3ED6);
        statusBg = const Color(0xFFEDE7F6);
        statusIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusBg,
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            slotLabel,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        trailing: status == 'Upcoming'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusBadge(status, statusColor, statusBg),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 22),
                    tooltip: 'Cancel',
                    onPressed: () => onCancel(
                        '$userName – ${formatMinutes(timeMinutes)} on $dateStr'),
                  ),
                ],
              )
            : _statusBadge(status, statusColor, statusBg),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
