import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/terms_screen.dart';

void main() {
  runApp(const ProviderScope(child: EazyAttendanceApp()));
}

class EazyAttendanceApp extends StatelessWidget {
  const EazyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eazy Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Auth is Phase 1. Later phases add '/dashboard', '/attendance',
      // '/settings' and put an auto-login gate on the initial route.
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/terms': (_) => const TermsScreen(),
      },
    );
  }
}