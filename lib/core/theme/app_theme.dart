import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// The single source of visual truth. Widgets are styled through this theme
/// rather than one-by-one, matching the website's design language.
class AppTheme {
  AppTheme._();

  // Radii from the website (--radius-*).
  static const double radiusSm = 6;
  static const double radiusMd = 12;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  // Standard control height for inputs & buttons (52px on the website).
  static const double controlHeight = 52;

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.blue500,
      onPrimary: AppColors.white,
      secondary: AppColors.blue600,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.gray800,
      error: AppColors.errorText,
      onError: AppColors.white,
      outline: AppColors.gray200,
    );

    final baseTextTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.gray50, // body background
      splashFactory: InkRipple.splashFactory, // native ripple
      fontFamily: GoogleFonts.dmSans().fontFamily,

      // ── Text ──
      // Each style already carries its intended colour (headings in blue-900,
      // body in gray-800), so we override slots individually rather than
      // calling .apply(), which would recolour every slot uniformly.
      textTheme: baseTextTheme.copyWith(
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.input,
        bodySmall: AppTextStyles.cardSubtitle,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.fieldLabel,
      ),

      // ── Inputs ── (mirrors .form-input: 52px, 1.5px border, 12px radius,
      //  blue-400 focus ring, gray-400 placeholder)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: false,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppTextStyles.placeholder,
        labelStyle: AppTextStyles.fieldLabel,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: _inputBorder(AppColors.gray200),
        enabledBorder: _inputBorder(AppColors.gray200),
        focusedBorder: _inputBorder(AppColors.blue400),
        errorBorder: _inputBorder(AppColors.errorBorder),
        focusedErrorBorder: _inputBorder(AppColors.errorBorder),
        errorStyle: AppTextStyles.error.copyWith(fontSize: 12.5),
      ),

      // ── Elevated (primary) button ── (mirrors .btn-primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.blue500.withValues(alpha: 0.55);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.blue700;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.blue600;
            }
            return AppColors.blue500;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          overlayColor:
          WidgetStatePropertyAll(AppColors.white.withValues(alpha: 0.08)),
          minimumSize: const WidgetStatePropertyAll(
            Size.fromHeight(controlHeight),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      // ── Text button (links, e.g. Terms) ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue500,
          textStyle: AppTextStyles.footer.copyWith(color: AppColors.blue500),
        ),
      ),

      // ── AppBar ── (mirrors .nav-bar: white, 60px, thin blue bottom border)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.blue900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: 60,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.blue900,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.blue600),
      ),

      // ── Cards ── (mirrors .card: white, 18px radius, subtle border/shadow)
      cardTheme: CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.gray100, width: 1.5),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.gray100,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}