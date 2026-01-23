import 'package:flutter/material.dart';
import '../../services/screens/home_screen.dart';
import '../../services/screens/camera_screen.dart';
import '../../services/screens/history_screen.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../services/screens/SettingsScreen.dart';
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  // Added SettingsScreen to the pages list
  final List<Widget> _pages = [
    const HomeScreen(),
    const CameraScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];