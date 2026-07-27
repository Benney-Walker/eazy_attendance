import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';


class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  void _toggle() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(), style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscured,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          autofillHints: widget.autofillHints,
          style: AppTextStyles.input,
          cursorColor: AppColors.blue500,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: AppColors.gray400),
            prefixIconConstraints:
            const BoxConstraints(minWidth: 46, minHeight: 46),
            suffixIcon: IconButton(
              onPressed: widget.enabled ? _toggle : null,
              splashRadius: 20,
              tooltip: _obscured ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.gray400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}