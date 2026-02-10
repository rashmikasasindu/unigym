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
  // 1. Track which tab is active (0=Gym, 1=Home, 2=Account)
  int _selectedIndex = 1;

  // 2. Track the specific content widget to show in the body
  // We initialize it with HomePage because that's our default
  late Widget _currentBody;

  @override
  void initState() {
    super.initState();
    // Pass a callback function to HomePage so it can tell us to change the view
    _currentBody = HomePage(onMenuSelected: _switchContent);
  }

  // This function swaps the body content but keeps the nav bar!
  void _switchContent(Widget newPage) {
    setState(() {
      _currentBody = newPage;
    });
  }

  // Handle Bottom Nav Bar Taps
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      // Define what happens for each tab
      if (index == 0) {
        _currentBody = const GymEquipmentPage();
      } else if (index == 1) {
        // RESET: If they click Home, we go back to the main grid
        _currentBody = HomePage(onMenuSelected: _switchContent);
      } else if (index == 2) {
        _currentBody = const UserAccountPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the gradient to show behind the floating bar
      // The body just shows whatever widget is currently selected
      body: _currentBody,
      
      // The Persistent Bottom Nav Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
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
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            )
          : Icon(icon, size: 30, color: color),
    );
  }
}