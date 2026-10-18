import 'package:eazy_attendance/core/theme/app_colors.dart';
import 'package:eazy_attendance/core/theme/app_text_styles.dart';
import 'package:eazy_attendance/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final authState = ref.watch(authControllerProvider).valueOrNull;
    final staffName = authState?.staffName ?? 'Teacher';
    final schoolName = authState?.institutionName ?? 'My School Name';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Overview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16, color: AppColors.gray600),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                        schoolName,
                        style: AppTextStyles.footer.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray600,
                        ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )

                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
           const Text('Welcome back,', style: AppTextStyles.sectionSubtitle),
          Text(
            staffName,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 24,
              color: AppColors.blue900
            ),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue100, width: 1.5)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.blue600,
                  size: 32
                ),
                const SizedBox(height: 12),
                const Text('Today\'s Overview', style: AppTextStyles.cardTitle),
                const SizedBox(height: 8),
                const Text(
                  'Your daily attendance statistics will appear here.',
                  style: AppTextStyles.footer,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

