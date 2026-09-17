import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../core/services/auth_service.dart';
import '../features/authentication/screens/pin_setup_screen.dart';
import '../features/authentication/screens/login_screen.dart';

class ApartmentManagementApp extends StatelessWidget {
  const ApartmentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartment Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _StartupGate(),
    );
  }
}

/// Decides, purely from local state, whether to show PIN setup (first run)
/// or the login screen — no network call is involved.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().hasPin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? const LoginScreen() : const PinSetupScreen();
      },
    );
  }
}
