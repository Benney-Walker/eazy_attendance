import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out', style: AppTextStyles.cardTitle),
        content: const Text('Are you sure you want to sign out?',
            style: AppTextStyles.cardSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    ) ??
        false;
    if (shouldLogout) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffName =
        ref.watch(authControllerProvider).valueOrNull?.staffName ?? 'Teacher';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.blue100, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 24, color: AppColors.blue600),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staffName,
                        style: AppTextStyles.input
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('Signed in as Teacher', style: AppTextStyles.footer),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout
          SizedBox(
            height: AppTheme.controlHeight,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorText,
                side: const BorderSide(color: AppColors.errorBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Eazy Attendance · Powered by Bynex Labs',
                style: AppTextStyles.footer),
          ),
        ],
      ),
    );
  }
}