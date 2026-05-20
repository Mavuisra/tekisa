library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../messaging/presentation/teacher_messages_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_grades_screen.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  static final _pages = <Widget>[
    const TeacherDashboardScreen(),
    const TeacherClassesScreen(),
    const TeacherGradesScreen(),
    const TeacherAttendanceScreen(),
    const TeacherMessagesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_index],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.76),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SalomonBottomBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: isDark
                  ? Colors.white70
                  : const Color(0xFF65676B),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  title: const Text('Accueil'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.class_outlined),
                  activeIcon: const Icon(Icons.class_),
                  title: const Text('Classes'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.grade_outlined),
                  activeIcon: const Icon(Icons.grade),
                  title: const Text('Notes'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.event_available_outlined),
                  activeIcon: const Icon(Icons.event_available),
                  title: const Text('Présences'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.chat_bubble_outline),
                  activeIcon: const Icon(Icons.chat_bubble),
                  title: const Text('Messages'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  title: const Text('Réglages'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
