import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_button.dart';
import '../application/auth_controller.dart';

class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final name = authState?.staffName;
    final greeting = (name == null || name.isEmpty) ? 'Welcome' : 'Welcome, $name';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eazy Attendance'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 56, color: AppColors.blue500),
              const SizedBox(height: 16),
              Text(greeting,
                  style: AppTextStyles.sectionTitle,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'You are signed in. The dashboard arrives in the next phase.',
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              LoadingButton(
                label: 'Log Out',
                icon: Icons.logout,
                expand: false,
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}