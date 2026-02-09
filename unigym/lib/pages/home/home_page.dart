import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/reservation_page.dart';
import '../features/workout_plans_page.dart';
import '../features/warmup_plans_page.dart';
import '../features/custom_workouts_page.dart';
import '../features/gym_equipment_page.dart';
import '../user/user_account_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Start with the 'Home' button selected

  // Function to handle bottom nav bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const GymEquipmentPage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAccountPage()));
    }
    // Index 1 is Home, so we do nothing (we are already here)
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      extendBody: true, // Important for the floating nav bar effect
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
                      title: "Custom Workouts",
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFFE8F5E9), // Light Green
                      iconColor: const Color(0xFF4CAF50), // Green
                      page: const CustomWorkoutsPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // --- CUSTOM BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: _buildCustomBottomNavBar(),
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

  // Custom Bottom Navigation Bar Widget
  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(icon: Icons.fitness_center, index: 0),
          _buildNavBarItem(icon: Icons.home_rounded, index: 1, isCenter: true),
          _buildNavBarItem(icon: Icons.person_rounded, index: 2),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({required IconData icon, required int index, bool isCenter = false}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFD932C6) : Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: isCenter
          ? Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFD932C6), // Purple for center button
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                ]
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            )
          : Icon(icon, size: 30, color: color),
    );
  }
}