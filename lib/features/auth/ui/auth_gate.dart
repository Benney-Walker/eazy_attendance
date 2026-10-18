import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';
import 'login_screen.dart';
import '../../../core/shell/home_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    ref.listen<AsyncValue<AuthState>>(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.valueOrNull?.status == AuthStatus.authenticated;
      final nowUnauthed =
          next.valueOrNull?.status == AuthStatus.unauthenticated;
      if (wasAuthed && nowUnauthed) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
      }
    });

    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const _AuthSplash(),
      error: (_, __) => const LoginScreen(), // fail safe → require login
      data: (state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            return const HomeShell();
          case AuthStatus.unauthenticated:
          case AuthStatus.unknown:
            return const LoginScreen();
        }
      },
    );
  }
}

/// Minimal branded splash shown only during the (near-instant) session read.
class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.loginBackground),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      ),
    );
  }
}