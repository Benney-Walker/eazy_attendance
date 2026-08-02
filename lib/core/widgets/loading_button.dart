import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Primary action button that shows a spinner + busy label while [loading],
/// and is disabled during that time — matching the website's Sign In button.
/// Colours/shape come from the themed [ElevatedButton] in [AppTheme].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.busyLabel,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Shown next to the spinner while loading. Defaults to "$label…".
  final String? busyLabel;

  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// When true (default) the button fills the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(busyLabel ?? '$label…'),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final Widget button = SizedBox(
      height: AppTheme.controlHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: child,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
