import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';

void main() {
  group('AppColors Palette & Tokens Tests', () {
    test('Primary palette colors are properly defined', () {
      expect(AppColors.primary, const Color(0xFF7C3AED));
      expect(AppColors.primaryDark, const Color(0xFF5B21B6));
      expect(AppColors.primaryLight, const Color(0xFFA78BFA));
      expect(AppColors.primarySoft, const Color(0xFFEDE9FE));
      expect(AppColors.primaryLavender, const Color(0xFFF3E8FF));
    });

    test('Macronutrient chip colors match Figma specifications', () {
      expect(AppColors.calorieColor, const Color(0xFFD97706));
      expect(AppColors.proteinColor, const Color(0xFF7C3AED));
      expect(AppColors.carbsColor, const Color(0xFF0284C7));
      expect(AppColors.fatColor, const Color(0xFFDC2626));
      expect(AppColors.sugarColor, const Color(0xFF475569));
    });

    test('Status and feedback colors have sufficient contrast tokens', () {
      expect(AppColors.success, const Color(0xFF10B981));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('Primary gradient contains at least two distinct color stops', () {
      expect(AppColors.primaryGradient.colors.length, greaterThanOrEqualTo(2));
      expect(AppColors.primaryGradient.colors.first, isNot(equals(AppColors.primaryGradient.colors.last)));
    });

    test('Splash background gradient starts with soft lavender', () {
      expect(AppColors.splashBackgroundGradient.colors.first, const Color(0xFFEDE9FE));
      expect(AppColors.splashBackgroundGradient.colors.last, Colors.white);
    });
  });
}
