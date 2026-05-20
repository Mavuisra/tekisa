import 'package:flutter/material.dart';

import 'login_screen.dart';

class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, always show login. Later, check stored tokens.
    return const LoginScreen();
  }
}

