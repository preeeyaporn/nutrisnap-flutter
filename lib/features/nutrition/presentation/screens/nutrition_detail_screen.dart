import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

class NutritionDetailScreen extends StatelessWidget {
  final FoodItem item;

  const NutritionDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ข้อมูลโภชนาการฉบับเต็ม',
          style: AppTypography.heading3.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<NutritionProvider>(
            builder: (context, provider, child) {
              final isFav = item.isFavorite;
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.error : AppColors.textPrimary,
                ),
                onPressed: () {
                  provider.toggleFavorite(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'ลบออกจากรายการโปรดแล้ว'
                            : 'เพิ่มในรายการโปรดแล้ว',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Product Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child:
                          item.imageUrl != null &&
                              item.imageUrl!.startsWith('assets/')
                          ? Image.asset(item.imageUrl!, fit: BoxFit.contain)
                          : const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTypography.heading3,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.nutriScore != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLavender,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'เกรด ${item.nutriScore}',
                                  style: AppTypography.chipText.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.brand.isNotEmpty ? "${item.brand} • " : ""}${item.servingSize}',
                          style: AppTypography.bodySmall,
                        ),
                        if (item.barcode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'บาร์โค้ด: ${item.barcode}',
                            style: AppTypography.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calories Highlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'พลังงานทั้งหมด',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          item.calories.toStringAsFixed(0),
                          style: AppTypography.heading1.copyWith(
                            fontSize: 44,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'กิโลแคลอรี่ (kcal)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'คิดเป็น ${(item.calories / 2000.0 * 100).toStringAsFixed(1)}% ของความต้องการพลังงานต่อวัน (2,000 kcal)',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Macronutrient Breakdown
            Text(
              'สารอาหารหลัก (Macronutrients)',
              style: AppTypography.heading3,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _MacroRow(
                    label: 'โปรตีน (Protein)',
                    grams: item.protein,
                    color: AppColors.proteinColor,
                    bgColor: AppColors.proteinBg,
                    percentage: (item.protein / 60.0).clamp(0.0, 1.0),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _MacroRow(
                    label: 'คาร์โบไฮเดรต (Carbohydrates)',
                    grams: item.carbohydrates,
                    color: AppColors.carbsColor,
                    bgColor: AppColors.carbsBg,
                    percentage: (item.carbohydrates / 300.0).clamp(0.0, 1.0),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _MacroRow(
                    label: 'ไขมันรวม (Total Fat)',
                    grams: item.fat,
                    color: AppColors.fatColor,
                    bgColor: AppColors.fatBg,
                    percentage: (item.fat / 65.0).clamp(0.0, 1.0),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _MacroRow(
                    label: 'น้ำตาล (Sugar)',
                    grams: item.sugar,
                    color: AppColors.sugarColor,
                    bgColor: AppColors.sugarBg,
                    percentage: (item.sugar / 25.0).clamp(0.0, 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Insight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryLavender,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บทวิเคราะห์จาก Gemini AI',
                          style: AppTypography.heading3.copyWith(
                            fontSize: 15,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'อาหารชนิดนี้มีคุณค่าทางโภชนาการอยู่ในเกณฑ์ ${item.nutriScore ?? "มาตรฐาน"} เหมาะสมต่อการบริโภคในชีวิตประจำวันอย่างสมดุล',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save to Log CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'บันทึก "${item.name}" ในบันทึกอาหารแล้ว',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: Text(
                  'บันทึกลงสมุดบันทึกอาหารประจำวัน',
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  final Color bgColor;
  final double percentage;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.color,
    required this.bgColor,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${grams.toStringAsFixed(1)} กรัม',
              style: AppTypography.heading3.copyWith(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
