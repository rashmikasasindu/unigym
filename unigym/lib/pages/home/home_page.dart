import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/reservation_page.dart';
import '../features/workout_plans_page.dart';
import '../features/warmup_plans_page.dart';
import '../features/gym_equipment_page.dart';
import '../user/user_account_page.dart';
import '../CheckIn/CheckIn_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      body: Container(
        // The Purple Gradient Theme
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
              // --- TOP BAR: Account Icon (left) ---
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserAccountPage()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 230, 58, 179), Color(0xFFD932C6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF5A2ED6),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- WELCOME BANNER ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, $displayName!",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Let's crush your goals today! 💪",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- FOUR BUTTONS GRID ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildMenuCard(
                      context,
                      title: "Reservation",
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFFF4F4F4), // Light gray/white
                      iconColor: const Color(0xFFD932C6), // Pink
                      page: const ReservationPage(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Workout Plans",
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFFE0F7FA), // Light Cyan
                      iconColor: const Color(0xFF00BCD4), // Cyan
                      page: const WorkoutPlansPage(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Warm-up Plans",
                      icon: Icons.directions_run_rounded,
                      color: const Color(0xFFFFF3E0), // Light Orange
                      iconColor: const Color(0xFFFF9800), // Orange
                      page: const WarmupPlansPage(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Check-in",
                      icon: Icons.qr_code_rounded,
                      color: const Color(0xFFEDE7F6), // Light Purple
                      iconColor: const Color(0xFF7C3AED), // Deep Purple
                      page: const CheckIn(),
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

  // Helper widget for the menu buttons
  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
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
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
