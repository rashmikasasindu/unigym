import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  Set<int> _attendedDays = {}; // Days of the current month the user attended
  bool _isLoading = true;

  // Calendar state
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
      return;
    }

    try {
      // Load user profile from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final userData = doc.data() ?? {};

      // Load attended days for the current calendar month
      final attendedDays = await _fetchAttendedDays(user.uid, _calendarMonth);

      if (mounted) {
        setState(() {
          _userData = userData;
          _attendedDays = attendedDays;
        });
      }
    } catch (e) {
      // Silently handle errors — UI will show with empty/default values
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  Future<Set<int>> _fetchAttendedDays(String uid, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: uid)
        .where('attended', isEqualTo: true)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    final days = <int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate();
      if (date != null) {
        days.add(date.day);
      }
    }
    return days;
  }

  Future<void> _changeMonth(int delta) async {
    final newMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + delta,
    );
    setState(() {
      _calendarMonth = newMonth;
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) return;
    final days = await _fetchAttendedDays(user.uid, newMonth);
    if (mounted) {
      setState(() {
        _attendedDays = days;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFD932C6)),
            SizedBox(width: 8),
            Text('Log Out'),
          ],
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD932C6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 20),
                          _buildUserDetailsCard(),
                          const SizedBox(height: 20),
                          _buildStreakBanner(),
                          const SizedBox(height: 20),
                          _buildCalendarCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Profile Header ────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    final email = _userData?['email'] ?? user?.email ?? 'User';
    final initials = _getInitials(email);
    final role = _userData?['role'] ?? 'Member';
    final regNum = _userData?['registration_number'] ?? '';

    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6EB7), Color(0xFF7C3AED)],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A3ED6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            email,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      role,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (regNum.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '# $regNum',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── User Details Card ──────────────────────────────────────────────────────

  Widget _buildUserDetailsCard() {
    final gender = _userData?['gender'] ?? 'N/A';
    final contact = _userData?['contact_number'] ?? 'N/A';
    final regNum = _userData?['registration_number'] ?? 'N/A';
    final role = _userData?['role'] ?? 'N/A';

    DateTime? createdAt;
    final raw = _userData?['created_at'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Profile Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(Icons.badge_rounded, 'Reg. Number', regNum),
          _detailRow(Icons.phone_rounded, 'Contact', contact),
          _detailRow(
              gender == 'Male'
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              'Gender',
              gender),
          _detailRow(Icons.admin_panel_settings_rounded, 'Role', role),
          if (createdAt != null)
            _detailRow(
              Icons.calendar_today_rounded,
              'Member Since',
              '${_monthName(createdAt.month)} ${createdAt.year}',
            ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak Banner ──────────────────────────────────────────────────────────

  Widget _buildStreakBanner() {
    final total = _attendedDays.length;
    final now = DateTime.now();
    final isCurrentMonth = _calendarMonth.year == now.year &&
        _calendarMonth.month == now.month;
    // Calculate current streak (consecutive days from today backward)
    int streak = 0;
    if (isCurrentMonth) {
      for (int d = now.day; d >= 1; d--) {
        if (_attendedDays.contains(d)) {
          streak++;
        } else {
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B35),
            label: 'Day Streak',
            value: '$streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF00E676),
            label: 'This Month',
            value: '$total sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFFFD700),
            label: 'Goal',
            value: total >= 20 ? '🏆 Hit!' : '${20 - total} left',
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Calendar Card ──────────────────────────────────────────────────────────

  Widget _buildCalendarCard() {
    final monthLabel =
        '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}';
    final daysInMonth =
        DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    final firstWeekday =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday % 7;
    // weekday: Mon=1..Sun=7, we display Sun=0 so mod 7 gives Sun=0

    final now = DateTime.now();
    final isCurrentMonth = _calendarMonth.year == now.year &&
        _calendarMonth.month == now.month;

    return _glassCard(
      child: Column(
        children: [
          // Calendar Header
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
                      const Text(
                        'Gym day  ',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11),
                      ),
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

          // Day-of-week labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grid of days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              final isToday = isCurrentMonth && day == now.day;
              final isAttended = _attendedDays.contains(day);

              return _buildDayCell(day, isToday, isAttended);
            },
          ),
          const SizedBox(height: 12),

          // Motivational message
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _attendedDays.isEmpty
                        ? 'No gym visits yet this month. Let\'s get started!'
                        : _attendedDays.length >= 15
                            ? 'You\'re a gym beast! Keep crushing it! 🔥'
                            : _attendedDays.length >= 8
                                ? 'Great consistency! Keep showing up! 🌟'
                                : 'Good start! Every session counts! ⚡',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, bool isToday, bool isAttended) {
    Color bgColor = Colors.transparent;
    Color textColor = Colors.white70;
    Border? border;
    BoxShadow? shadow;
    Widget? badge;

    if (isAttended) {
      bgColor = const Color(0xFF00E676);
      textColor = Colors.white;
      shadow = BoxShadow(
        color: const Color(0xFF00E676).withValues(alpha: 0.5),
        blurRadius: 8,
        spreadRadius: 1,
      );
      badge = const Positioned(
        top: 2,
        right: 2,
        child: Icon(Icons.check_circle, color: Colors.white, size: 9),
      );
    } else if (isToday) {
      border = Border.all(color: Colors.white, width: 2);
      textColor = Colors.white;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: border,
            boxShadow: shadow != null ? [shadow] : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight:
                    (isAttended || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }

  // ── Logout Button ──────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFD932C6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
          shadowColor: Colors.black38,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  String _getInitials(String email) {
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  String _monthName(int month) {
    const names = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}
