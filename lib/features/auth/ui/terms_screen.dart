import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_button.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Terms of Service',
                        style: AppTextStyles.sectionTitle,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('Service terms will be published soon.',
                        style: AppTextStyles.cardSubtitle,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'We are currently preparing our official terms and '
                          'conditions to ensure transparency and compliance.',
                      style: AppTextStyles.cardSubtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(
                      label: 'Go Back',
                      expand: false,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}