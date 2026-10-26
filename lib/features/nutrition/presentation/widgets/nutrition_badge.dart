import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

enum NutrientType { calories, protein, carbs, fat, sugar, fiber }

class NutritionBadge extends StatelessWidget {
  final String label;
  final String? value;
  final NutrientType type;

  const NutritionBadge({
    super.key,
    required this.label,
    this.value,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = switch (type) {
      NutrientType.calories => (AppColors.calorieColor, AppColors.calorieBg),
      NutrientType.protein => (AppColors.proteinColor, AppColors.proteinBg),
      NutrientType.carbs => (AppColors.carbsColor, AppColors.carbsBg),
      NutrientType.fat => (AppColors.fatColor, AppColors.fatBg),
      NutrientType.sugar => (AppColors.sugarColor, AppColors.sugarBg),
      NutrientType.fiber => (AppColors.success, AppColors.successLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            value != null ? '$label $value' : label,
            style: AppTypography.chipText.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
