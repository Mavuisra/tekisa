library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/support/support_contact.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../data/django_auth_service.dart';
import '../../admin/presentation/admin_shell.dart';
import 'login_screen.dart';
import '../../home/presentation/home_shell.dart';
import '../../onboarding/presentation/first_login_onboarding_screen.dart';
import '../../teacher/presentation/teacher_shell.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  final _authService = djangoAuthService;
  final _local = AuthLocalDataSource();
  bool _checked = false;
  bool _isLoggedIn = false;
  String? _role;
  String? _userId;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    final user = _local.getUser();
    var showOnboarding = false;
    if (loggedIn && user != null && user.id.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(_onboardingKey(user.id)) ?? false;
      showOnboarding = !done;
    }
    if (!mounted) return;
    setState(() {
      _checked = true;
      _isLoggedIn = loggedIn;
      _role = user?.role;
      _userId = user?.id;
      _showOnboarding = showOnboarding;
    });
  }

  String _onboardingKey(String userId) => 'tekisa_onboarding_done_$userId';

  Widget _homeByRole() {
    final role = (_role ?? '').toLowerCase();
    if (role == 'super_admin' || role == 'school_admin') {
      return const AdminShell();
    }
    if (role == 'teacher') return const TeacherShell();
    return const HomeShell();
  }

  Future<void> _finishOnboarding() async {
    final id = (_userId ?? '').trim();
    if (id.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey(id), true);
    }
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  Future<void> _openSupport() async {
    await openWhatsAppSupport();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isLoggedIn) return const LoginScreen();
    if (_showOnboarding) {
      return FirstLoginOnboardingScreen(
        userRole: _role ?? '',
        onFinished: _finishOnboarding,
        onContactSupport: _openSupport,
      );
    }
    return _homeByRole();
  }
}
