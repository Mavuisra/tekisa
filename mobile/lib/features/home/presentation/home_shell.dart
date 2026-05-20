import 'package:flutter/material.dart';

import '../../attendance/presentation/attendance_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../grades/presentation/grades_screen.dart';
import '../../messaging/presentation/messages_screen.dart';
import '../../payments/presentation/payments_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static final _pages = <Widget>[
    const DashboardScreen(),
    const GradesScreen(),
    const AttendanceScreen(),
    const PaymentsScreen(),
    const MessagesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            label: 'Présences',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Paiements',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}

