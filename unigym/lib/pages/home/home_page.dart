import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/reservation_page.dart';
import '../features/workout_plans_page.dart';
import '../features/warmup_plans_page.dart';
import '../features/custom_workouts_page.dart';

class HomePage extends StatelessWidget {
  // This callback allows HomePage to talk to MainScreen
  final Function(Widget) onMenuSelected;

  const HomePage({super.key, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Container(
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
            // --- WELCOME BANNER ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 5),
                          const Text("Let's crush your goals today! 💪", style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                    title: "Reservation",
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFFF4F4F4),
                    iconColor: const Color(0xFFD932C6),
                    page: const ReservationPage(),
                    borderColor: const Color(0xFFD932C6), // Border Color
                  ),
                  _buildMenuCard(
                    title: "Workout Plans",
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFFE0F7FA),
                    iconColor: const Color(0xFF00BCD4),
                    page: const WorkoutPlansPage(),
                    borderColor: const Color(0xFF00BCD4),
                  ),
                  _buildMenuCard(
                    title: "Warm-up Plans",
                    icon: Icons.directions_run_rounded,
                    color: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                    page: const WarmupPlansPage(),
                    borderColor: const Color(0xFFFF9800),
                  ),
                  _buildMenuCard(
                    title: "Custom Workouts",
                    icon: Icons.edit_note_rounded,
                    color: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                    page: const CustomWorkoutsPage(),
                    borderColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
            
            // Spacer to prevent content from hiding behind the nav bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Widget page,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () {
        // Instead of Navigator.push, we use the callback to swap the body in MainScreen
        onMenuSelected(page);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          // --- ADDED BORDER HERE ---
          border: Border.all(
            color: borderColor,
            width: 2.0, // Thickness of the border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                color: iconColor.withOpacity(0.2),
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