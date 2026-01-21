import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';

<<<<<<< HEAD
import 'package:easy_localization/easy_localization.dart'; 

import 'screens/SettingsScreen.dart'; 
=======
import 'package:easy_localization/easy_localization.dart';
import 'screens/SettingsScreen.dart';
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}
<<<<<<< HEAD
class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Added SettingsScreen to the pages list
=======

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
  final List<Widget> _pages = [
    const HomeScreen(),
    const CameraScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_filled),
<<<<<<< HEAD
              label: 'nav_home'.tr(), 
=======
              label: 'nav_home'.tr(), // Localized
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.camera_alt_outlined),
              activeIcon: const Icon(Icons.camera_alt),
<<<<<<< HEAD
              label: 'nav_scan'.tr(), 
=======
              label: 'nav_scan'.tr(), // Localized
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history),
<<<<<<< HEAD
              label: 'nav_history'.tr(), 
=======
              label: 'nav_history'.tr(), // Localized
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
<<<<<<< HEAD
              label: 'nav_settings'.tr(), 
=======
              label: 'nav_settings'.tr(), // Localized
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
