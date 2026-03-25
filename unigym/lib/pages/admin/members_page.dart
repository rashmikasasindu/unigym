import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  static const Color _gradientTop = Color(0xFFD932C6);
  static const Color _gradientBottom = Color(0xFF4A3ED6);

  String _searchQuery = '';

  // Returns true if the user has been scanned / attended today
  bool _isInGymToday(Map<String, dynamic> userData) {
    final lastCheckin = userData['lastCheckinDate'];
    if (lastCheckin == null) return false;
    final date = lastCheckin is Timestamp
        ? lastCheckin.toDate()
        : DateTime.tryParse(lastCheckin.toString());
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Checks the reservations collection to find if a member attended today
  Stream<List<String>> _getTodayAttendedUids() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('attended', isEqualTo: true)
        .where('attendedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('attendedAt', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => (doc.data()['userId'] as String?) ?? '')
            .where((uid) => uid.isNotEmpty)
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Members',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 12),
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
                      hintText: 'Search members…',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Content panel
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
                  child: StreamBuilder<List<String>>(
                    stream: _getTodayAttendedUids(),
                    builder: (context, attendedSnap) {
                      final attendedUids =
                          attendedSnap.data ?? [];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .orderBy('name')
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final allDocs = snap.data?.docs ?? [];
                          final filtered = allDocs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final name = (data['name'] as String? ?? '')
                                .toLowerCase();
                            final email = (data['email'] as String? ?? '')
                                .toLowerCase();
                            final q = _searchQuery.toLowerCase();
                            return name.contains(q) || email.contains(q);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'No members found.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15),
                              ),
                            );
                          }

                          // Counts
                          final inGymCount = filtered.where((doc) {
                            return attendedUids
                                .contains(doc.id);
                          }).length;

                          return Column(
                            children: [
                              // Stats row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 24, 20, 8),
                                child: Row(
                                  children: [
                                    _statChip(
                                      label: 'Total Members',
                                      value: filtered.length.toString(),
                                      color: const Color(0xFF4A3ED6),
                                    ),
                                    const SizedBox(width: 12),
                                    _statChip(
                                      label: 'In Gym Today',
                                      value: inGymCount.toString(),
                                      color: const Color(0xFF00C97C),
                                    ),
                                  ],
                                ),
                              ),
                              // List
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 32),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final doc = filtered[index];
                                    final data = doc.data()
                                        as Map<String, dynamic>;
                                    final name =
                                        data['name'] as String? ?? 'Unknown';
                                    final email =
                                        data['email'] as String? ?? '';
                                    final regNum =
                                        data['registration_number']
                                            as String? ??
                                            '';
                                    final gender =
                                        data['gender'] as String? ?? '';
                                    final isInGym =
                                        attendedUids.contains(doc.id);

                                    return _MemberCard(
                                      name: name,
                                      email: email,
                                      regNum: regNum,
                                      gender: gender,
                                      isInGym: isInGym,
                                    );
                                  },
                                ),
                              ),
                            ],
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

  Widget _statChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String email;
  final String regNum;
  final String gender;
  final bool isInGym;

  const _MemberCard({
    required this.name,
    required this.email,
    required this.regNum,
    required this.gender,
    required this.isInGym,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

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
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEDE7F6),
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3ED6),
                  fontSize: 16,
                ),
              ),
            ),
            // Status dot
            Positioned(
              bottom: 0,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isInGym
                      ? const Color(0xFF00C97C)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              email,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            if (regNum.isNotEmpty)
              Text(
                'Reg: $regNum${gender.isNotEmpty ? '  ·  $gender' : ''}',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
          ],
        ),
        trailing: isInGym
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'In Gym',
                  style: TextStyle(
                    color: Color(0xFF00C97C),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
