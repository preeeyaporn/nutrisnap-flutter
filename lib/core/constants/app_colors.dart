import 'package:flutter/material.dart';

/// App color palette matching the NutriSnap Figma design specifications.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple / Violet
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primarySoft = Color(0xFFEDE9FE);
  static const Color primaryLavender = Color(0xFFF3E8FF);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerReticleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashBackgroundGradient = LinearGradient(
    colors: [Color(0xFFEDE9FE), Color(0xFFF8FAFC), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF18181B);
  static const Color cardDark = Color(0xFF27272A);
  static const Color darkOverlay = Color(0xCC18181B);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color neutralSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Colors.white;
  static const Color textSecondaryOnDark = Color(0xFFD1D5DB);

  // Macronutrient Chip Colors (from Figma Screen 2 & 4)
  static const Color calorieColor = Color(0xFFD97706);
  static const Color calorieBg = Color(0xFFFEF3C7);

  static const Color proteinColor = Color(0xFF7C3AED);
  static const Color proteinBg = Color(0xFFEDE9FE);

  static const Color carbsColor = Color(0xFF0284C7);
  static const Color carbsBg = Color(0xFFE0F2FE);

  static const Color fatColor = Color(0xFFDC2626);
  static const Color fatBg = Color(0xFFFEE2E2);

  static const Color sugarColor = Color(0xFF475569);
  static const Color sugarBg = Color(0xFFF1F5F9);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);
}
