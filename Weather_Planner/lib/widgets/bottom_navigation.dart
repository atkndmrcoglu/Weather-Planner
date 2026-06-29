import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/ai_planner_screen.dart';
import '../screens/my_routes_screen.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const MapScreen(),
    const AiPlannerScreen(),
    const MyRoutesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildModernNavbar(),
    );
  }

  Widget _buildModernNavbar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Arka plan bulanıklığı
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.1), // Yarı transparan arka plan
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.2), // Zarif bir çerçeve
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.wb_twilight, 'Weather', 0),
                  _buildNavItem(Icons.map_outlined, 'Map', 1),
                  _buildNavItem(Icons.animation_outlined, 'AI', 2),
                  _buildNavItem(Icons.bookmark_outline, 'Saved', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}