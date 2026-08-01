import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_button.dart';
import '../application/auth_controller.dart';

/// Login screen — the native Android counterpart of the website's login page.
///
/// Phase 1 scope: full UI + client-side validation only. The real
/// `POST /auth/v1/staff-login` call, secure token storage, and navigation to
/// the dashboard are wired in Phase 2 (see the marked TODO).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _error = null);

    final staffId = _staffIdController.text.trim();
    final password = _passwordController.text;

    if (staffId.isEmpty) {
      setState(() => _error = 'Please enter your Staff ID.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }

    setState(() => _loading = true);

    // Real login. On success the AuthController flips global auth state and the
    // AuthGate swaps this screen for the signed-in home automatically — so
    // there's no manual navigation here. On failure we show the mapped message.
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(staffId: staffId, password: password);
      // Success: no-op. The gate rebuilds and replaces this screen.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'An unexpected error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.loginBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _LoginHero(),
                      const SizedBox(height: 36),
                      _LoginCard(
                        staffIdController: _staffIdController,
                        passwordController: _passwordController,
                        passwordFocus: _passwordFocus,
                        error: _error,
                        loading: _loading,
                        onSubmit: _handleLogin,
                        onTermsTap: () =>
                            Navigator.of(context).pushNamed('/terms'),
                      ),
                      const SizedBox(height: 24),
                      Text('Powered by Bynex Labs',
                          style: AppTextStyles.versionBadge),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Branding block: glassy icon badge, app name, tagline.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.18),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(Icons.school_outlined,
              size: 36, color: AppColors.white),
        ),
        const SizedBox(height: 16),
        const Text('Eazy Attendance',
            style: AppTextStyles.heroTitle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Smart attendance for modern schools',
            style: AppTextStyles.heroSubtitle, textAlign: TextAlign.center),
      ],
    );
  }
}

/// The white login card: heading, optional error banner, inputs, Sign In,
/// and the Terms footer.
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.staffIdController,
    required this.passwordController,
    required this.passwordFocus,
    required this.error,
    required this.loading,
    required this.onSubmit,
    required this.onTermsTap,
  });

  final TextEditingController staffIdController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue500.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            const Text('Sign in to manage student attendance',
                style: AppTextStyles.cardSubtitle),
            const SizedBox(height: 22),
            if (error != null) ...[
              _ErrorBanner(message: error!),
              const SizedBox(height: 16),
            ],
            AppTextField(
              label: 'Staff ID',
              hint: 'ST******',
              controller: staffIdController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.username],
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onSubmitted: (_) => passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 18),
            AppPasswordField(
              label: 'Password',
              hint: 'Enter your password',
              controller: passwordController,
              focusNode: passwordFocus,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 22),
            LoadingButton(
              label: 'Sign In',
              busyLabel: 'Authenticating…',
              icon: Icons.login,
              loading: loading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("By signing in you agree to the system's ",
                      style: AppTextStyles.footer),
                  GestureDetector(
                    onTap: onTermsTap,
                    child: Text(
                      'Terms of Service',
                      style: AppTextStyles.footer
                          .copyWith(color: AppColors.blue500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline error banner — the native equivalent of `.error-msg.visible`.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        border: Border.all(color: AppColors.errorBorder, width: 1.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.errorText),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTextStyles.error)),
        ],
      ),
    );
  }
}