import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'progress/progress_screen.dart';
import 'support/support_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProgressScreen(),
    SupportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const activeColor = Color(0xFF5300AC);
    const inactiveColor = Color(0xFFAAAAAA);

    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.show_chart_rounded, 'Progress'),
      (Icons.headset_mic_outlined, 'Support'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = i;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[i].$1,
                  color: active ? activeColor : inactiveColor,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? activeColor : inactiveColor,
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
