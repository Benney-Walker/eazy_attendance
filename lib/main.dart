import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/ui/auth_gate.dart';
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
      // The gate performs auto-login and shows either the signed-in home or the
      // login screen. Phase 3+ add '/dashboard', '/attendance', '/settings'.
      home: const AuthGate(),
      routes: {
        '/terms': (_) => const TermsScreen(),
      },
    );
  }
}