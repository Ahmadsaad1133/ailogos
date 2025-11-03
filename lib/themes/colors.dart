import 'package:flutter/material.dart';

/// Centralized color palette for the Powered by OBSDIV app.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF060510);
  static const Color surface = Color(0xFF0E0C1F);
  static const Color surfaceElevated = Color(0xFF171333);
  static const Color accent = Color(0xFF6B4DFF);
  static const Color accentSecondary = Color(0xFF00E0FF);
  static const Color accentTertiary = Color(0xFF9B51FF);
  static const Color success = Color(0xFF00FFC6);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF4D67);
  static const Color textPrimary = Color(0xFFF3F5FF);
  static const Color textSecondary = Color(0xFFB7BEE1);
  static const Color outline = Color(0xFF2E2A4A);

  static Gradient neonBackgroundGradient({Color? accentColor}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      (accentColor ?? accent).withOpacity(0.28),
      accentSecondary.withOpacity(0.12),
      Colors.black.withOpacity(0.7),
    ],
  );
}