import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Base DM Sans style with the website's default text colour.
  static TextStyle get _sans => GoogleFonts.dmSans(color: AppColors.gray800);

  /// Base DM Mono style (IDs, dates, stat numbers).
  static TextStyle get _mono => GoogleFonts.dmMono(color: AppColors.gray800);

  // ── Login hero ──
  static TextStyle get heroTitle => _sans.copyWith(
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
  /// "Welcome back" — 1.15rem / 700 / blue-900.
  static TextStyle get cardTitle => _sans.copyWith(
    fontSize: 18.4,
    fontWeight: FontWeight.w700,
    color: AppColors.blue900,
  );

  /// "Sign in to manage..." — 0.85rem / gray-600.
  static TextStyle get cardSubtitle => _sans.copyWith(
    fontSize: 13.6,
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
  );

  // ── Section headers (dashboard/attendance — used from Phase 3) ──
  static TextStyle get sectionTitle => _sans.copyWith(
    fontSize: 22.4, // 1.4rem
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
    color: AppColors.blue900,
  );

  static TextStyle get sectionSubtitle => _sans.copyWith(
    fontSize: 14, // 0.875rem
    color: AppColors.gray600,
  );

  // ── Form field label (uppercase, tracked) ──
  static TextStyle get fieldLabel => _sans.copyWith(
    fontSize: 12.8, // 0.8rem
    fontWeight: FontWeight.w600,
    color: AppColors.gray600,
    letterSpacing: 0.3,
  );

  // ── Input text & placeholder ──
  static TextStyle get input => _sans.copyWith(
    fontSize: 16, // 1rem
    fontWeight: FontWeight.w400,
    color: AppColors.gray800,
  );

  static TextStyle get placeholder => input.copyWith(color: AppColors.gray400);

  // ── Buttons ──
  static TextStyle get button => _sans.copyWith(
    fontSize: 16, // 1rem
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // ── Error banner ──
  static TextStyle get error => _sans.copyWith(
    fontSize: 14, // 0.875rem
    fontWeight: FontWeight.w500,
    color: AppColors.errorText,
  );

  // ── Footer / version ──
  static TextStyle get footer => _sans.copyWith(
    fontSize: 12.8, // 0.8rem
    color: AppColors.gray400,
  );

  static TextStyle get versionBadge => _sans.copyWith(
    fontSize: 11.5, // 0.72rem
    color: AppColors.white.withValues(alpha: 0.45),
  );

  // ── Monospace (IDs, dates, stat numbers) — used from Phase 3 ──
  static TextStyle get mono => _mono.copyWith(fontSize: 12);
}