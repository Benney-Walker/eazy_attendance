import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/ui/auth_gate.dart';

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
      home: const AuthGate(),
    );
  }
}
