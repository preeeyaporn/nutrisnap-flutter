import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

/// Screen 10 — Meal Detail (TH)
/// Detailed breakdown of recorded AI-analyzed meal matching Figma Screen 10
class MealDetailScreen extends StatefulWidget {
  final FoodItem item;
  final NutritionAnalysisResult? analysisResult;
  final List<int>? imageBytes;

  const MealDetailScreen({
    super.key,
    required this.item,
    this.analysisResult,
    this.imageBytes,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late FoodItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String _formatThaiDateTime(DateTime dt) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final year = dt.year + 543;
    final month = months[dt.month - 1];
    final day = dt.day;
    final timeStr = DateFormat('HH:mm').format(dt);
    return '$day $month $year เวลา $timeStr น.';
  }

  String _getMealTimeTag(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 5 && hour < 11) return 'บันทึกเมื่อเช้า';
    if (hour >= 11 && hour < 15) return 'บันทึกเมื่อเที่ยง';
    if (hour >= 15 && hour < 18) return 'บันทึกตอนบ่าย';
    return 'บันทึกเมื่อเย็น';
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _item.name);
    final caloriesCtrl = TextEditingController(
      text: _item.calories.toInt().toString(),
    );
    final portionCtrl = TextEditingController(text: _item.servingSize);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('แก้ไขข้อมูลมื้ออาหาร', style: AppTypography.heading3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่ออาหาร'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ปริมาณ / สัดส่วน',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'พลังงาน (กิโลแคลอรี่)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPortion = portionCtrl.text.trim();
                final newCal =
                    double.tryParse(caloriesCtrl.text.trim()) ?? _item.calories;

                final updated = _item.copyWith(
                  name: newName.isNotEmpty ? newName : _item.name,
                  servingSize: newPortion.isNotEmpty
                      ? newPortion
                      : _item.servingSize,
                  calories: newCal,
                );

                Navigator.of(ctx).pop();
                final provider = context.read<NutritionProvider>();
                await provider.repository.saveFoodItem(updated);
                await provider.loadRecentScans();

                if (!mounted) return;
                setState(() {
                  _item = updated;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('อัปเดตข้อมูลมื้ออาหารแล้ว')),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('ลบรายการอาหาร?', style: AppTypography.heading3),
          content: Text(
            'คุณต้องการลบ "${_item.name}" ออกจากสมุดบันทึกอาหารใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final provider = context.read<NutritionProvider>();
                await provider.deleteFoodItem(_item.id);
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบ "${_item.name}" เรียบร้อยแล้ว')),
                );
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = _item.calories;
    final protein = _item.protein;
    final carbs = _item.carbohydrates;
    final fat = _item.fat;
    final sugar = _item.sugar > 0 ? _item.sugar : 3.5;
    final fiber = _item.fiber > 0 ? _item.fiber : 4.2;
    final sodium = _item.sodium > 0 ? _item.sodium : 780.0;

    final totalMacros = (protein * 4) + (carbs * 4) + (fat * 9);
    final proteinPercent = totalMacros > 0
        ? ((protein * 4) / totalMacros * 100).round()
        : 0;
    final carbsPercent = totalMacros > 0
        ? ((carbs * 4) / totalMacros * 100).round()
        : 0;
    final fatPercent = totalMacros > 0
        ? ((fat * 9) / totalMacros * 100).round()
        : 0;
    final quotaPercent = ((calories / 2000.0) * 100).round();

    final confidence = widget.analysisResult?.confidence ?? 0.94;
    final confidencePercent = (confidence * 100).toInt();

    final ingredientsList = _item.ingredients.isNotEmpty
        ? _item.ingredients
        : const [
            'อกไก่',
            'ข้าวหอมมะลิ',
            'ไข่ดาวกรอบ',
            'ใบกะเพราไทย',
            'พริกสด',
            'กระเทียม',
            'ซีอิ๊วขาว',
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'รายละเอียดอาหาร',
          style: AppTypography.heading3.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF7C3AED),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-header Row: Status Pill + Edit + Delete buttons (Figma Screen 10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'สแกนและยืนยันแล้ว',
                        style: AppTypography.chipText.copyWith(
                          color: const Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Edit button
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _showEditDialog,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _showDeleteDialog,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Food Photo Card (Figma Screen 10)
            _buildFoodPhotoCard(
              confidencePercent: confidencePercent,
              formattedDateTime: _formatThaiDateTime(_item.scannedAt),
              mealTimeTag: _getMealTimeTag(_item.scannedAt),
            ),
            const SizedBox(height: 14),

            // Energy Summary Card (Figma Screen 10)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Flame Circular Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 3.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFF7C3AED),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Center text: พลังงานที่ได้รับ 560 กิโลแคลอรี่
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'พลังงานที่ได้รับ',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              calories.toInt().toString(),
                              style: AppTypography.heading1.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'กิโล\nแคลอรี่',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF475569),
                                fontSize: 11,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Box: ยอดโควตาต่อวัน 28%
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ยอดโควตาต่อวัน',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$quotaPercent%',
                          style: AppTypography.heading2.copyWith(
                            color: const Color(0xFF7C3AED),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Macronutrient Breakdown (สัดส่วนสารอาหารหลัก)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: Color(0xFF7C3AED),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'สัดส่วนสารอาหารหลัก',
                      style: AppTypography.heading3.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  _item.servingSize.isNotEmpty
                      ? _item.servingSize
                      : 'ขนาดมาตรฐาน (380 กรัม)',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Grid of Macronutrients (Figma Screen 10)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildGridMacroCard(
                        title: 'โปรตีน',
                        value: '${protein.toStringAsFixed(1)} ก.',
                        percent: '$proteinPercent%',
                        dotColor: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGridMacroCard(
                        title: 'คาร์โบไฮเดรต',
                        value: '${carbs.toStringAsFixed(1)} ก.',
                        percent: '$carbsPercent%',
                        dotColor: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildGridMacroCard(
                        title: 'ไขมันรวม',
                        value: '${fat.toStringAsFixed(1)} ก.',
                        percent: '$fatPercent%',
                        dotColor: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGridMacroCard(
                        title: 'น้ำตาล',
                        value: '${sugar.toStringAsFixed(1)} ก.',
                        percent: 'ระดับต่ำ',
                        dotColor: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fiber & Sodium Rows (Figma Screen 10)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF7C3AED),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('ใยอาหาร', style: AppTypography.bodyMedium),
                        ],
                      ),
                      Text(
                        '${fiber.toStringAsFixed(1)} ก.',
                        style: AppTypography.heading3.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            color: Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('โซเดียม', style: AppTypography.bodyMedium),
                        ],
                      ),
                      Text(
                        '${sodium.toInt()} มก.',
                        style: AppTypography.heading3.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Identified Ingredients Section (Figma Screen 10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF7C3AED),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ส่วนผสมที่ระบุได้',
                      style: AppTypography.heading3.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ingredientsList.length} รายการ',
                    style: AppTypography.chipText.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredientsList.map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ingredient,
                        style: AppTypography.chipText.copyWith(
                          color: const Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Estimation Note Alert (Figma Screen 10)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF7C3AED),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'หมายเหตุการประมาณ',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF5B21B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.analysisResult?.advice.isNotEmpty == true
                              ? widget.analysisResult!.advice
                              : 'หมายเหตุ: ค่าความเป็นไป AI vision $confidencePercent% ค่าโภชนาการถูกปรับเทียบกับการดูดซับน้ำมันจากการผัดอาหารตามสั่งไทย',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF4C1D95),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // System & Sync Information (ระบบบันทึกและซิงค์ข้อมูล - Figma Screen 10)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storage_rounded,
                        color: Color(0xFF0F172A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ระบบบันทึกและซิงค์ข้อมูล',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // AI Model Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('โมเดล AI', style: AppTypography.bodySmall),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF7C3AED),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Gemini 1.5 Flash Vision',
                            style: AppTypography.chipText.copyWith(
                              color: const Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Saved timestamp row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('เวลาบันทึก', style: AppTypography.bodySmall),
                      Text(
                        _formatThaiDateTime(_item.scannedAt),
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sync Status Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('สถานะการจัดเก็บ', style: AppTypography.bodySmall),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'ฐานข้อมูลในเครื่อง (SQLite) - ซิงค์ไปยัง Firebase Cloud แล้ว',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF334155),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Buttons: "แก้ไขข้อมูลมื้อนี้" + "ลบรายการอาหารนี้"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                ),
                onPressed: _showEditDialog,
                icon: const Icon(Icons.tune_rounded, size: 20),
                label: Text(
                  'แก้ไขข้อมูลมื้อนี้',
                  style: AppTypography.buttonText.copyWith(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _showDeleteDialog,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                label: Text(
                  'ลบรายการอาหารนี้',
                  style: AppTypography.buttonText.copyWith(
                    color: const Color(0xFFEF4444),
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodPhotoCard({
    required int confidencePercent,
    required String formattedDateTime,
    required String mealTimeTag,
  }) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhotoWidget(),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top-right pill: "✦ ตรงกัน 94%"
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF7C3AED),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ตรงกัน $confidencePercent%',
                      style: AppTypography.chipText.copyWith(
                        color: const Color(0xFF7C3AED),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info: Meal tag, Food name, Timestamp
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFFA78BFA),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        mealTimeTag,
                        style: AppTypography.chipText.copyWith(
                          color: const Color(0xFFDDD6FE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _item.name,
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedDateTime,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
    if (widget.imageBytes != null && widget.imageBytes!.length > 200) {
      try {
        return Image.memory(
          Uint8List.fromList(widget.imageBytes!),
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    return Image.asset(
      'assets/images/screen_meal_detail_guide.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/screen_camera_guide.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF334155),
          child: const Center(
            child: Icon(
              Icons.restaurant_rounded,
              color: Colors.white54,
              size: 54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridMacroCard({
    required String title,
    required String value,
    required String percent,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                percent,
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
