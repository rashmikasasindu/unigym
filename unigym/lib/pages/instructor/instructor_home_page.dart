import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/workout_plans_page.dart';
import '../features/warmup_plans_page.dart';
import 'instructor_account_page.dart';
import 'instructor_reservation_page.dart';
import 'instructor_checkin_page.dart';
import 'instructor_members_page.dart';
import 'instructor_progress_page.dart';

/// Home screen shown exclusively to users with role = "instructor".
class InstructorHomePage extends StatelessWidget {
  const InstructorHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Instructor';

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Welcome Banner ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Account icon (left)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const InstructorAccountPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $displayName!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '🏋️ Instructor',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout icon (right)
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white70),
                        tooltip: 'Log Out',
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Label ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Instructor Tools',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 6-Card Grid ───────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildCard(
                      context,
                      title: 'Workout Plans',
                      subtitle: 'Add & manage workout plans',
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFFE0F7FA),
                      iconColor: const Color(0xFF00BCD4),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const WorkoutPlansPage(isInstructor: true),
                        ),
                      ),
                    ),
                    _buildCard(
                      context,
                      title: 'Warm-up Plans',
                      subtitle: 'Add & manage warm-up plans',
                      icon: Icons.directions_run_rounded,
                      color: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFFF9800),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const WarmupPlansPage(isInstructor: true),
                        ),
                      ),
                    ),
                    _buildCard(
                      context,
                      title: 'Reserve a Slot',
                      subtitle: 'Book your gym sessions',
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFFEDE7F6),
                      iconColor: const Color(0xFF7B1FA2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const InstructorReservationPage(),
                        ),
                      ),
                    ),
                    _buildCard(
                      context,
                      title: 'Check-In',
                      subtitle: 'View your QR & attendance',
                      icon: Icons.qr_code_rounded,
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF388E3C),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorCheckInPage(),
                        ),
                      ),
                    ),
                    _buildCard(
                      context,
                      title: 'My Members',
                      subtitle: 'View member reservations',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFFF0F4FF),
                      iconColor: const Color(0xFF4A3ED6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorMembersPage(),
                        ),
                      ),
                    ),
                    _buildCard(
                      context,
                      title: 'Progress',
                      subtitle: 'Track member attendance',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFE8FFF3),
                      iconColor: const Color(0xFF00C97C),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorProgressPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
