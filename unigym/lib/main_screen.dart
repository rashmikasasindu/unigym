import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';
import 'pages/features/gym_equipment_page.dart';
import 'pages/user/user_account_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Track which tab is active (0=Gym, 1=Home, 2=Account)
  int _selectedIndex = 1;

  // The pages for each tab
  static const List<Widget> _pages = [
    GymEquipmentPage(),
    HomePage(),
    UserAccountPage(),
  ];

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
      ),
    );
  }

  Widget _buildNavBarItem({required IconData icon, required int index, bool isCenter = false}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFD932C6) : Colors.grey;

    return GestureDetector(
      onTap: () => _onNavBarTapped(index),
      child: isCenter
          ? Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFD932C6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            )
          : Icon(icon, size: 30, color: color),
    );
  }
}
