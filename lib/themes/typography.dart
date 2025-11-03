import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Defines typography styles that are reused across the app.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color accent) {
    final base = GoogleFonts.orbitronTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 1.4,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.1,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: accent,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: AppColors.textSecondary.withOpacity(0.7),
        height: 1.5,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: accent,
      ),
    );
  }
}