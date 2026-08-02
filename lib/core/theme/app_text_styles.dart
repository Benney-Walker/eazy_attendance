import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography for the app. Body text uses **DM Sans**, numeric / ID / date
/// text uses **DM Mono** — the same families and weights the website loads
/// (DM Sans 400/500/600/700, DM Mono 400/500).
///
/// Fonts are bundled as assets (see pubspec.yaml), referenced here by family
/// name. Defined once — do not construct ad-hoc `TextStyle`s in widgets; pull
/// from this class or from `Theme.of(context).textTheme`.
class AppTextStyles {
  AppTextStyles._();

  /// Bundled font family names — must match the `family:` keys in pubspec.yaml.
  static const String fontSans = 'DM Sans';
  static const String fontMono = 'DM Mono';

  static const TextStyle _sans =
      TextStyle(fontFamily: fontSans, color: AppColors.gray800);

  // ── Login hero ──
  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 27.2, // 1.7rem
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle get heroSubtitle => _sans.copyWith(
        fontSize: 14.4, // 0.9rem
        fontWeight: FontWeight.w400,
        color: AppColors.white.withValues(alpha: 0.75),
      );

  // ── Card headings ──
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 18.4, // 1.15rem
    fontWeight: FontWeight.w700,
    color: AppColors.blue900,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 13.6, // 0.85rem
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
  );

  // ── Section headers (dashboard/attendance — used from Phase 4) ──
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 22.4, // 1.4rem
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
    color: AppColors.blue900,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 14, // 0.875rem
    color: AppColors.gray600,
  );

  // ── Form field label (uppercase, tracked) ──
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontSans,
    fontSize: 12.8, // 0.8rem
    fontWeight: FontWeight.w600,
    color: AppColors.gray600,
    letterSpacing: 0.3,
  );

  // ── Input text & placeholder ──
  static const TextStyle input = TextStyle(
    fontFamily: fontSans,
    fontSize: 16, // 1rem
    fontWeight: FontWeight.w400,
    color: AppColors.gray800,
  );

  static TextStyle get placeholder => input.copyWith(color: AppColors.gray400);

  // ── Buttons ──
  static const TextStyle button = TextStyle(
    fontFamily: fontSans,
    fontSize: 16, // 1rem
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // ── Error banner ──
  static const TextStyle error = TextStyle(
    fontFamily: fontSans,
    fontSize: 14, // 0.875rem
    fontWeight: FontWeight.w500,
    color: AppColors.errorText,
  );

  // ── Footer / version ──
  static const TextStyle footer = TextStyle(
    fontFamily: fontSans,
    fontSize: 12.8, // 0.8rem
    color: AppColors.gray400,
  );

  static TextStyle get versionBadge => footer.copyWith(
        fontSize: 11.5, // 0.72rem
        color: AppColors.white.withValues(alpha: 0.45),
      );

  // ── Monospace (IDs, dates, stat numbers) — used from Phase 4 ──
  static const TextStyle mono = TextStyle(
    fontFamily: fontMono,
    fontSize: 12,
    color: AppColors.gray800,
  );
}
