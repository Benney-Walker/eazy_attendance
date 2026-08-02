import 'package:flutter/material.dart';

/// Colour palette extracted verbatim from the website's `Styles.css` `:root`.
/// Do not hardcode colours inside widgets — reference these constants.
class AppColors {
  AppColors._();

  // ── Blues (primary brand scale) ──
  static const Color blue900 = Color(0xFF0C2461); // --blue-900
  static const Color blue700 = Color(0xFF1A4FA0); // --blue-700
  static const Color blue600 = Color(0xFF1E5CBF); // --blue-600
  static const Color blue500 = Color(0xFF2563EB); // --blue-500  (primary)
  static const Color blue400 = Color(0xFF3B82F6); // --blue-400
  static const Color blue300 = Color(0xFF93C5FD); // --blue-300 fallback
  static const Color blue200 = Color(0xFFBFDBFE); // --blue-200
  static const Color blue100 = Color(0xFFDBEAFE); // --blue-100
  static const Color blue50 = Color(0xFFEFF6FF); // --blue-50

  // ── Neutrals ──
  static const Color white = Color(0xFFFFFFFF); // --white
  static const Color gray50 = Color(0xFFF8FAFC); // --gray-50
  static const Color gray100 = Color(0xFFF1F5F9); // --gray-100
  static const Color gray200 = Color(0xFFE2E8F0); // --gray-200
  static const Color gray400 = Color(0xFF94A3B8); // --gray-400
  static const Color gray600 = Color(0xFF475569); // --gray-600
  static const Color gray800 = Color(0xFF1E293B); // --gray-800

  // ── Feedback ──
  static const Color errorBg = Color(0xFFFEF2F2); // .error-msg background
  static const Color errorBorder = Color(0xFFFCA5A5); // .error-msg border
  static const Color errorText = Color(0xFFDC2626); // .error-msg / toast.error

  // ── Login hero gradient (CSS linear-gradient 160deg) ──
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment(-0.5, -1.0),
    end: Alignment(0.5, 1.0),
    colors: [blue900, blue600, blue400],
    stops: [0.0, 0.5, 1.0],
  );
}
