import 'package:flutter/material.dart';

import 'widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'all_courses_screen.dart';

// Global key to control bottom nav selection from child screens
final GlobalKey<_NavbarscreenState> navBarKey = GlobalKey<_NavbarscreenState>();

class Navbarscreen extends StatefulWidget {
  const Navbarscreen({super.key});

  @override
  State<Navbarscreen> createState() => _NavbarscreenState();
}

class _NavbarscreenState extends State<Navbarscreen> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Public method to allow external screens to change tab
  void setIndex(int index) => _onNavTapped(index);

  final List<Widget> _screens = [
    HomeScreen(),
    const ProgressScreen(),
    const AllCoursesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
