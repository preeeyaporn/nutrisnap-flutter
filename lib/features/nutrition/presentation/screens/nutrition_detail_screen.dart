import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

/// Full Nutrition Details Screen (Screen 5: Barcode Result / รายละเอียดอาหาร)
/// Designed pixel-perfect matching Figma Screen 5 specifications:
/// - Open Food Facts verification badge & barcode pill
/// - Product card with Nutri-Score badge & Net Weight badge
/// - Portion size adjuster (🥣 ปรับปริมาณบริโภค) with presets, slider, and stepper
/// - Calculated energy card with circular flame gauge 🔥, daily calorie %, and accurate food classification
/// - 2x2 Macronutrient breakdown cards (โปรตีน, คาร์โบไฮเดรต, ไขมันรวม, น้ำตาล) with progress bars
/// - Micronutrients breakdown (ใยอาหาร, โซเดียม, ไขมันอิ่มตัว)
/// - Full Nutrition Data Management:
///   1) Bulk / Dynamic Database Refresh (ข้ามรายการที่ผู้ใช้แก้ไขเอง is_user_edited = true)
///   2) Manual Nutrition Override (แก้ไขข้อมูลโภชนาการครบทุกช่องด้วยตนเอง)
///   3) Report Inaccurate Data (รายงานข้อมูลไม่ตรงกับซองจริงไปยัง Backend / Firebase)
class NutritionDetailScreen extends StatefulWidget {
  final FoodItem item;
  final OpenFoodFactsService? openFoodFactsService;

  const NutritionDetailScreen({
    super.key,
    required this.item,
    this.openFoodFactsService,
  });

  @override
  State<NutritionDetailScreen> createState() => _NutritionDetailScreenState();
}

class _NutritionDetailScreenState extends State<NutritionDetailScreen> {
  late FoodItem _currentItem;
  bool _isRefreshing = false;
  double _portionMultiplier = 1.0;
  int _selectedPortionIndex = 0;
  double? _customWeightGrams;

  @override
  void initState() {
    super.initState();
    if (!widget.item.isUserEdited && widget.item.barcode.isNotEmpty) {
      final verified = OpenFoodFactsServiceImpl.getCatalogItemIfPresent(
        widget.item.barcode,
      );
      _currentItem = verified != null
          ? verified.copyWith(
              id: widget.item.id,
              isFavorite: widget.item.isFavorite,
              scannedAt: widget.item.scannedAt,
            )
          : widget.item;
    } else {
      _currentItem = widget.item;
    }
  }

  /// ดึงตัวเลขน้ำหนักตั้งต้น (กรัม หรือ มล.) จาก servingSize อย่างแม่นยำ
  /// เช่น "1 ซอง (25 กรัม)" -> 25.0, "46 กรัม" -> 46.0, "330 มล." -> 330.0
  double get _baseWeight {
    final unitMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:กรัม|ก\.|มล\.|มล|grams?|g\b|ml\b)',
      caseSensitive: false,
    ).firstMatch(_currentItem.servingSize);
    if (unitMatch != null) {
      final val = double.tryParse(unitMatch.group(1)!);
      if (val != null && val > 0) return val;
    }
    final allMatches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(_currentItem.servingSize);
    if (allMatches.isNotEmpty) {
      final val = double.tryParse(allMatches.last.group(1)!);
      if (val != null && val > 0) return val;
    }
    return 100.0;
  }

  /// ตรวจสอบหน่วยว่าเป็น มล. (เครื่องดื่ม) หรือ กรัม (อาหาร/ขนม)
  String get _unitLabel {
    final s = _currentItem.servingSize.toLowerCase();
    if (s.contains('มล') || s.contains('ml')) {
      return 'มล.';
    }
    return 'กรัม';
  }

  /// น้ำหนักสุทธิปัจจุบันที่กำลังคำนวณอยู่
  double get _effectiveWeight => _customWeightGrams ?? (_baseWeight * _portionMultiplier);

  /// เปิดกล่องให้ผู้ใช้พิมพ์ปริมาณกรัม/มล. และพลังงาน (kcal) ตามหน้าซองจริงได้ทันที
  Future<void> _showCustomWeightDialog() async {
    final currentKcal = _currentItem.calories * _portionMultiplier;
    final weightController = TextEditingController(
      text: _effectiveWeight.toStringAsFixed(
        _effectiveWeight == _effectiveWeight.roundToDouble() ? 0 : 1,
      ),
    );
    final kcalController = TextEditingController(
      text: currentKcal.toStringAsFixed(0),
    );

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.scale_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ปรับปริมาณและพลังงานตามหน้าซอง',
                style: AppTypography.heading3.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พิมพ์ปริมาณสุทธิ ($_unitLabel) ระบบจะคำนวณแคลอรี่ตามสัดส่วนให้อัตโนมัติ หรือพิมพ์พลังงาน (kcal) ให้ตรงกับกรอบ GDA หน้าซองได้เลย',
              style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                final parsedW = double.tryParse(val.trim());
                if (parsedW != null && parsedW > 0 && _baseWeight > 0) {
                  final autoKcal = _currentItem.calories * (parsedW / _baseWeight);
                  kcalController.text = autoKcal.toStringAsFixed(0);
                }
              },
              decoration: InputDecoration(
                labelText: 'ปริมาณสุทธิ ($_unitLabel)',
                hintText: 'เช่น 25, 46, 69, 100',
                suffixText: _unitLabel,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'พลังงานตามหน้าซอง (kcal)',
                hintText: 'เช่น 140, 240, 360',
                suffixText: 'kcal',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final parsedW = double.tryParse(weightController.text.trim());
              final parsedKcal = double.tryParse(kcalController.text.trim());
              if (parsedW != null && parsedW > 0) {
                Navigator.of(ctx).pop({
                  'weight': parsedW,
                  if (parsedKcal != null && parsedKcal >= 0) 'kcal': parsedKcal,
                });
              }
            },
            child: const Text('บันทึกค่า', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result['weight'] != null) {
      final newWeight = result['weight']!;
      final newKcal = result['kcal'];
      final ratio = _baseWeight > 0 ? (newWeight / _baseWeight) : 1.0;

      if (newKcal != null && _currentItem.calories > 0) {
        final autoKcal = _currentItem.calories * ratio;
        if ((newKcal - autoKcal).abs() >= 1.0) {
          final updated = _currentItem.copyWith(
            calories: newKcal,
            servingSize: '${newWeight.toStringAsFixed(newWeight == newWeight.roundToDouble() ? 0 : 1)} $_unitLabel',
            protein: _currentItem.protein * ratio,
            carbohydrates: _currentItem.carbohydrates * ratio,
            fat: _currentItem.fat * ratio,
            sugar: _currentItem.sugar * ratio,
            fiber: _currentItem.fiber * ratio,
            sodium: _currentItem.sodium * ratio,
            isUserEdited: true,
          );
          setState(() {
            _currentItem = updated;
            _customWeightGrams = null;
            _portionMultiplier = 1.0;
            _selectedPortionIndex = 0;
          });
          if (!mounted) return;
          final provider = Provider.of<NutritionProvider?>(context, listen: false);
          await provider?.updateFoodItemManual(updated);
          return;
        }
      }

      setState(() {
        _customWeightGrams = newWeight;
        _portionMultiplier = ratio;
        _selectedPortionIndex = -1;
      });
    }
  }

  /// Reloads fresh product and nutrition data from Open Food Facts API
  Future<void> _refreshFromOpenFoodFacts() async {
    if (_currentItem.barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่มีรหัสบาร์โค้ดสำหรับดึงข้อมูลจาก Open Food Facts',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      final offService = widget.openFoodFactsService ?? OpenFoodFactsServiceImpl();
      final result = await offService.getProductByBarcode(_currentItem.barcode);

      if (!mounted) return;

      result.when(
        success: (freshItem) {
          setState(() {
            _currentItem = freshItem.copyWith(
              isFavorite: _currentItem.isFavorite,
              isUserEdited: false,
            );
            _isRefreshing = false;
          });

          final nutritionProvider = Provider.of<NutritionProvider?>(context, listen: false);
          nutritionProvider?.setCurrentProduct(_currentItem);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'อัปเดตข้อมูลโภชนาการจาก Open Food Facts สำเร็จ',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        failure: (message, _) {
          setState(() => _isRefreshing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่สามารถดึงข้อมูลล่าสุดได้: $message',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// 1. ระบบอัปเดตและ Refresh ฐานข้อมูลอาหารทั้งหมด (Bulk / Dynamic Update)
  Future<void> _bulkRefreshAllFoodItems() async {
    setState(() => _isRefreshing = true);
    final provider = Provider.of<NutritionProvider?>(context, listen: false);
    final updatedCount =
        await provider?.refreshAllDatabaseItems(overwriteUserEdited: false) ?? 0;
    if (!mounted) return;
    setState(() {
      if (provider?.currentProduct != null &&
          provider!.currentProduct!.barcode == _currentItem.barcode &&
          !_currentItem.isUserEdited) {
        _currentItem = provider.currentProduct!;
      }
      _isRefreshing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'อัปเดตฐานข้อมูลอาหารสำเร็จ ($updatedCount รายการ) โดยคงค่าที่คุณแก้ไขเองไว้',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  /// 2. ฟังก์ชันแก้ไขข้อมูลโภชนาการด้วยตนเองครบทุกช่อง (User Manual Override / Edit Food Details)
  Future<void> _showEditNutritionBottomSheet() async {
    final weightCtrl = TextEditingController(
      text: _baseWeight.toStringAsFixed(
        _baseWeight == _baseWeight.roundToDouble() ? 0 : 1,
      ),
    );
    final servingsCtrl = TextEditingController(
      text: _currentItem.servingsPerContainer.toStringAsFixed(
        _currentItem.servingsPerContainer ==
                _currentItem.servingsPerContainer.roundToDouble()
            ? 0
            : 1,
      ),
    );
    final kcalCtrl = TextEditingController(
      text: _currentItem.calories.toStringAsFixed(0),
    );
    final proteinCtrl = TextEditingController(
      text: _currentItem.protein.toStringAsFixed(1),
    );
    final carbsCtrl = TextEditingController(
      text: _currentItem.carbohydrates.toStringAsFixed(1),
    );
    final fatCtrl = TextEditingController(
      text: _currentItem.fat.toStringAsFixed(1),
    );
    final sugarCtrl = TextEditingController(
      text: _currentItem.sugar.toStringAsFixed(1),
    );
    final sodiumCtrl = TextEditingController(
      text: _currentItem.sodium.toStringAsFixed(0),
    );
    final satFatCtrl = TextEditingController(
      text: _currentItem.saturatedFat.toStringAsFixed(1),
    );
    final fiberCtrl = TextEditingController(
      text: _currentItem.fiber.toStringAsFixed(1),
    );

    void recalculateAtwaterKcal() {
      final p = double.tryParse(proteinCtrl.text.trim()) ?? 0.0;
      final c = double.tryParse(carbsCtrl.text.trim()) ?? 0.0;
      final f = double.tryParse(fatCtrl.text.trim()) ?? 0.0;
      final autoKcal = (p * 4.0) + (c * 4.0) + (f * 9.0);
      kcalCtrl.text = autoKcal.round().toString();
    }

    final edited = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'แก้ไขข้อมูลโภชนาการ (Edit Nutrition Info)',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  'ระบุค่าตามฉลากจริง เมื่อบันทึกแล้วระบบจะตั้งค่า is_user_edited = true เพื่อไม่ให้ถูกเขียนทับเมื่อซิงค์ข้อมูลรอบใหม่',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditField(
                        controller: weightCtrl,
                        label: 'ปริมาณสุทธิ ($_unitLabel)',
                        suffix: _unitLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditField(
                        controller: servingsCtrl,
                        label: 'จำนวนหน่วยบริโภค/ซอง',
                        suffix: 'ครั้ง',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditField(
                        controller: kcalCtrl,
                        label: 'พลังงานรวม (kcal)',
                        suffix: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: recalculateAtwaterKcal,
                      icon: const Icon(
                        Icons.calculate_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'คำนวณจากสารอาหาร',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditField(
                        controller: proteinCtrl,
                        label: 'โปรตีน (Protein)',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditField(
                        controller: carbsCtrl,
                        label: 'คาร์โบไฮเดรต (Carbs)',
                        suffix: 'g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditField(
                        controller: fatCtrl,
                        label: 'ไขมันรวม (Total Fat)',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditField(
                        controller: sugarCtrl,
                        label: 'น้ำตาล (Sugar)',
                        suffix: 'g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditField(
                        controller: sodiumCtrl,
                        label: 'โซเดียม (Sodium)',
                        suffix: 'mg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditField(
                        controller: satFatCtrl,
                        label: 'ไขมันอิ่มตัว',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditField(
                        controller: fiberCtrl,
                        label: 'ใยอาหาร',
                        suffix: 'g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'บันทึกการแก้ไขและคำนวณสัดส่วนใหม่',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      final w =
                          double.tryParse(weightCtrl.text.trim()) ?? _baseWeight;
                      final srv =
                          double.tryParse(servingsCtrl.text.trim()) ?? 1.0;
                      final updated = _currentItem.copyWith(
                        servingSize:
                            '${w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1)} $_unitLabel',
                        servingsPerContainer: srv > 0 ? srv : 1.0,
                        calories: double.tryParse(kcalCtrl.text.trim()) ??
                            _currentItem.calories,
                        protein: double.tryParse(proteinCtrl.text.trim()) ??
                            _currentItem.protein,
                        carbohydrates:
                            double.tryParse(carbsCtrl.text.trim()) ??
                                _currentItem.carbohydrates,
                        fat: double.tryParse(fatCtrl.text.trim()) ??
                            _currentItem.fat,
                        sugar: double.tryParse(sugarCtrl.text.trim()) ??
                            _currentItem.sugar,
                        sodium: double.tryParse(sodiumCtrl.text.trim()) ??
                            _currentItem.sodium,
                        saturatedFat:
                            double.tryParse(satFatCtrl.text.trim()) ??
                                _currentItem.saturatedFat,
                        fiber: double.tryParse(fiberCtrl.text.trim()) ??
                            _currentItem.fiber,
                        isUserEdited: true,
                        scannedAt: DateTime.now(),
                      );
                      Navigator.of(ctx).pop(updated);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (edited != null) {
      setState(() {
        _currentItem = edited;
        _customWeightGrams = null;
        _portionMultiplier = 1.0;
        _selectedPortionIndex = 0;
      });
      if (!mounted) return;
      final provider = Provider.of<NutritionProvider?>(context, listen: false);
      await provider?.updateFoodItemManual(edited);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'บันทึกข้อมูลโภชนาการใหม่เรียบร้อยแล้ว (is_user_edited: true)',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11.5),
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 3. ระบบรายงานข้อมูลผิดพลาด (Report Inaccurate Data)
  Future<void> _showReportDataDialog() async {
    final noteCtrl = TextEditingController(
      text: _currentItem.reportNote ??
          'ค่าพลังงาน/น้ำหนักสุทธิบนแอปไม่ตรงกับกรอบ GDA หน้าซองจริง',
    );
    final correctKcalCtrl = TextEditingController(
      text: _currentItem.calories.toStringAsFixed(0),
    );
    final correctWeightCtrl = TextEditingController(
      text: _baseWeight.toStringAsFixed(
        _baseWeight == _baseWeight.roundToDouble() ? 0 : 1,
      ),
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Color(0xFFEA580C), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'รายงานข้อมูลไม่ถูกต้อง (Report Data)',
                style: AppTypography.heading3.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รหัสบาร์โค้ด: ${_currentItem.barcode.isEmpty ? "-" : _currentItem.barcode}\nส่ง Flag พร้อมแนบค่าที่ถูกต้องตามบรรจุภัณฑ์ไปยัง Firebase เพื่อปรับปรุงฐานข้อมูลกลาง',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดความคลาดเคลื่อน',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildEditField(
                      controller: correctWeightCtrl,
                      label: 'น้ำหนักหน้าซองจริง',
                      suffix: _unitLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEditField(
                      controller: correctKcalCtrl,
                      label: 'พลังงานหน้าซองจริง',
                      suffix: 'kcal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'ส่งรายงาน & อัปเดต',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (submitted == true) {
      final newW =
          double.tryParse(correctWeightCtrl.text.trim()) ?? _baseWeight;
      final newKcal =
          double.tryParse(correctKcalCtrl.text.trim()) ?? _currentItem.calories;
      final ratio = _baseWeight > 0 ? (newW / _baseWeight) : 1.0;

      final corrected = _currentItem.copyWith(
        servingSize:
            '${newW.toStringAsFixed(newW == newW.roundToDouble() ? 0 : 1)} $_unitLabel',
        calories: newKcal,
        protein: _currentItem.protein * ratio,
        carbohydrates: _currentItem.carbohydrates * ratio,
        fat: _currentItem.fat * ratio,
        sugar: _currentItem.sugar * ratio,
        sodium: _currentItem.sodium * ratio,
        isUserEdited: true,
        isReported: true,
        reportNote: noteCtrl.text.trim(),
      );

      setState(() {
        _currentItem = corrected;
        _customWeightGrams = null;
        _portionMultiplier = 1.0;
        _selectedPortionIndex = 0;
      });

      if (!mounted) return;
      final provider = Provider.of<NutritionProvider?>(context, listen: false);
      await provider?.reportInaccurateData(
        item: widget.item,
        correctedItem: corrected,
        reason: noteCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'ส่งรายงานข้อมูลไม่ถูกต้องไปยังระบบและอัปเดตค่าตามหน้าซองแล้ว',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read user daily calorie target from AuthProvider, defaulting to Thai RDI recommendation (2,000 kcal)
    final authProvider = Provider.of<AuthProvider?>(context, listen: false);
    final double dailyCalorieTarget =
        authProvider?.currentUser?.dailyCalorieTarget ?? 2000.0;

    // Dynamically calculate nutrients based on portion multiplier
    final double calories = _currentItem.calories * _portionMultiplier;
    final double protein = _currentItem.protein * _portionMultiplier;
    final double carbs = _currentItem.carbohydrates * _portionMultiplier;
    final double fat = _currentItem.fat * _portionMultiplier;
    final double sugar = _currentItem.sugar * _portionMultiplier;
    final double fiber = _currentItem.fiber * _portionMultiplier;
    final double saturatedFat = _currentItem.saturatedFat * _portionMultiplier;
    final double sodium = _currentItem.sodium * _portionMultiplier;

    final double caloriePercent =
        dailyCalorieTarget > 0 ? (calories / dailyCalorieTarget * 100.0) : 0.0;
    final double calorieProgress = (caloriePercent / 100.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          children: [
            Text(
              'รายละเอียดอาหาร',
              style: AppTypography.heading3.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'ข้อมูลโภชนาการฉบับเต็ม',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            tooltip: 'แก้ไขข้อมูลโภชนาการ',
            onPressed: _showEditNutritionBottomSheet,
          ),
          if (_currentItem.barcode.isNotEmpty)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.sync_rounded, color: AppColors.primary),
              tooltip: 'รีเฟรชข้อมูลจาก Open Food Facts',
              onPressed: _isRefreshing ? null : _refreshFromOpenFoodFacts,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFromOpenFoodFacts,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Verification Badges Row (Open Food Facts API & Barcode)
              _buildTopVerificationBadges(),
              const SizedBox(height: 14),

              // 2. Product Information Card (Figma Screen 5)
              _buildProductCard(),
              const SizedBox(height: 16),

              // 3. Portion Size Adjuster (🥣 ปรับปริมาณบริโภค)
              _buildPortionAdjusterCard(calculatedCalories: calories),
              const SizedBox(height: 16),

              // 4. Calorie Card with Flame Gauge (พลังงานที่คำนวณได้)
              _buildCalculatedEnergyCard(
                calories: calories,
                dailyTarget: dailyCalorieTarget,
                caloriePercent: caloriePercent,
                calorieProgress: calorieProgress,
              ),
              const SizedBox(height: 18),

              // 5. 2x2 Macronutrient Colored Cards (สารอาหารหลัก)
              _buildMacronutrientsSection(
                protein: protein,
                carbs: carbs,
                fat: fat,
                sugar: sugar,
              ),
              const SizedBox(height: 16),

              // 6. Micronutrients List (ใยอาหาร, โซเดียม, ไขมันอิ่มตัว)
              _buildMicronutrientsCard(
                fiber: fiber,
                sodium: sodium,
                saturatedFat: saturatedFat,
              ),
              const SizedBox(height: 16),

              // 7. Local & Cloud Storage Sync Status
              _buildDatabaseSyncStatusCard(),
              const SizedBox(height: 12),

              // 7.5. Nutrition Data Management (Edit Nutrition Info, Report Data, Bulk Refresh)
              _buildDataManagementActionsCard(),
              const SizedBox(height: 16),

              // 8. AI Nutritional Insights (บทวิเคราะห์จาก Gemini AI)
              _buildAiInsightCard(
                calories: calories,
                protein: protein,
                fat: fat,
                sugar: sugar,
                sodium: sodium,
              ),
              const SizedBox(height: 20),

              // 9. Rescan Barcode Bar
              _buildRescanBarcodeBar(),
              const SizedBox(height: 12),

              // 10. Main CTA Button (บันทึกมื้ออาหารลงไดอารี่)
              _buildSaveButton(context),
              const SizedBox(height: 10),

              // 11. Secondary Action
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.textSecondary),
                  label: Text(
                    'สแกนรายการอื่น',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Badges: Open Food Facts Verification & Barcode Pill
  Widget _buildTopVerificationBadges() {
    return Row(
      children: [
        // Open Food Facts Badge
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ตรวจสอบแล้วโดย Open Food Facts API',
                    style: AppTypography.chipText.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_currentItem.barcode.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_rounded, color: Color(0xFF64748B), size: 14),
                const SizedBox(width: 5),
                Text(
                  _currentItem.barcode,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 2. Product Card (Image, Brand, Name, Nutri-Score & Net Weight Badges)
  Widget _buildProductCard() {
    final grade = _currentItem.nutriScore ?? 'A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Thumbnail
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildFoodImage(),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentItem.brand.isNotEmpty
                      ? _currentItem.brand
                      : 'ข้อมูลอาหารที่ผ่านการวิเคราะห์',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _currentItem.name,
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildNutriScoreBadge(grade),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ปริมาณสุทธิ ${_effectiveWeight.toStringAsFixed(_effectiveWeight == _effectiveWeight.roundToDouble() ? 0 : 1)} $_unitLabel',
                        style: AppTypography.chipText.copyWith(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_currentItem.servingsPerContainer > 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ควรแบ่งกินประมาณ ${_currentItem.servingsPerContainer.toStringAsFixed(0)} ครั้ง',
                          style: AppTypography.chipText.copyWith(
                            color: const Color(0xFF0369A1),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_currentItem.isUserEdited)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'แก้ไขเองแล้ว',
                          style: AppTypography.chipText.copyWith(
                            color: const Color(0xFF065F46),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to display food thumbnail safely
  Widget _buildFoodImage() {
    final imgUrl = _currentItem.imageUrl;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      if (imgUrl.startsWith('assets/')) {
        return Image.asset(imgUrl, fit: BoxFit.contain);
      } else if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        return Image.network(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.restaurant_rounded,
            color: AppColors.primary,
            size: 34,
          ),
        );
      }
    }
    return const Icon(
      Icons.restaurant_rounded,
      color: AppColors.primary,
      size: 34,
    );
  }

  /// Nutri-Score badge
  Widget _buildNutriScoreBadge(String grade) {
    final cleanGrade = grade.toUpperCase().replaceAll('เกรด', '').trim();
    Color bg;
    Color fg = Colors.white;

    switch (cleanGrade) {
      case 'A':
        bg = const Color(0xFF15803D);
        break;
      case 'B':
        bg = const Color(0xFF65A30D);
        break;
      case 'C':
        bg = const Color(0xFFCA8A04);
        break;
      case 'D':
        bg = const Color(0xFFEA580C);
        break;
      case 'E':
        bg = const Color(0xFFDC2626);
        break;
      default:
        bg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'เกรด $cleanGrade',
        style: AppTypography.chipText.copyWith(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 3. Portion Size Adjuster Card (🥣 ปรับปริมาณบริโภค)
  Widget _buildPortionAdjusterCard({required double calculatedCalories}) {
    final isDrink = _unitLabel == 'มล.';
    final baseW = _baseWeight;
    final currentW = _effectiveWeight;
    final sliderMax = isDrink ? math.max(1000.0, baseW * 2) : math.max(300.0, baseW * 2);
    final sliderValue = currentW.clamp(5.0, sliderMax);

    // ตัวเลือกปริมาณมาตรฐานแบบคลีนๆ และตัดตัวเลขที่ซ้ำกับค่าบนฉลากออกอัตโนมัติ
    final rawPresets = isDrink
        ? <double>[180.0, 250.0, 330.0, 500.0]
        : <double>[25.0, 50.0, 100.0];
    final presetWeights = rawPresets.where((w) => (w - baseW).abs() >= 1.0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🥣', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ปรับปริมาณบริโภค',
                        style: AppTypography.heading3.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ปุ่มกดพิมพ์ตัวเลขกรัม/มล. ได้ทันที
              InkWell(
                onTap: _showCustomWeightDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${currentW.toStringAsFixed(currentW == currentW.roundToDouble() ? 0 : 1)} $_unitLabel (${calculatedCalories.toStringAsFixed(0)} kcal)',
                        style: AppTypography.chipText.copyWith(
                          color: AppColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Portion Selectable Chips (ไม่ซ้ำซ้อน แสดงเฉพาะตัวเลขสุทธิ)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPortionChip(
                  index: 0,
                  label: '1 หน่วย (${baseW.toStringAsFixed(baseW == baseW.roundToDouble() ? 0 : 1)} $_unitLabel)',
                  multiplier: 1.0,
                  targetWeight: baseW,
                ),
                if (_currentItem.servingsPerContainer > 1.0) ...[
                  const SizedBox(width: 8),
                  _buildPortionChip(
                    index: 99,
                    label:
                        'แบ่งกิน 1 ครั้ง (${(baseW / _currentItem.servingsPerContainer).toStringAsFixed(0)} $_unitLabel)',
                    multiplier: 1.0 / _currentItem.servingsPerContainer,
                    targetWeight: baseW / _currentItem.servingsPerContainer,
                  ),
                ],
                for (int i = 0; i < presetWeights.length; i++) ...[
                  const SizedBox(width: 8),
                  _buildPortionChip(
                    index: i + 1,
                    label: '${presetWeights[i].toInt()} $_unitLabel',
                    multiplier: presetWeights[i] / baseW,
                    targetWeight: presetWeights[i],
                  ),
                ],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showCustomWeightDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPortionIndex == -1
                          ? const Color(0xFF1E1B4B)
                          : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: _selectedPortionIndex == -1 ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ระบุเอง',
                          style: AppTypography.bodySmall.copyWith(
                            color: _selectedPortionIndex == -1 ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // แถบเลื่อนปรับปริมาณกรัม/มล. อิสระ
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFEDE9FE),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: sliderValue,
              min: 5.0,
              max: sliderMax,
              divisions: ((sliderMax - 5.0) / 5.0).round().clamp(1, 200),
              label: '${sliderValue.round()} $_unitLabel',
              onChanged: (val) {
                setState(() {
                  final rounded = (val / 5.0).round() * 5.0;
                  _customWeightGrams = rounded;
                  _portionMultiplier = rounded / baseW;
                  _selectedPortionIndex = -1;
                });
              },
            ),
          ),

          // Stepper & Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'คำนวณจากปริมาณสุทธิ: ${currentW.toStringAsFixed(currentW == currentW.roundToDouble() ? 0 : 1)} $_unitLabel = ${calculatedCalories.toStringAsFixed(0)} แคลอรี่',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stepper [-] x1 [+]
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 16, color: Color(0xFF334155)),
                      onPressed: () {
                        if (_portionMultiplier > 0.5) {
                          setState(() {
                            _customWeightGrams = null;
                            _portionMultiplier = (_portionMultiplier - 0.5).clamp(0.5, 5.0);
                          });
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'x${_portionMultiplier.toStringAsFixed(1).replaceAll('.0', '')}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF334155)),
                      onPressed: () {
                        if (_portionMultiplier < 5.0) {
                          setState(() {
                            _customWeightGrams = null;
                            _portionMultiplier = (_portionMultiplier + 0.5).clamp(0.5, 5.0);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortionChip({
    required int index,
    required String label,
    required double multiplier,
    double? targetWeight,
  }) {
    final isSelected = _selectedPortionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPortionIndex = index;
          _portionMultiplier = multiplier;
          _customWeightGrams = index == 0 ? null : targetWeight;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 4. จำแนกหมวดหมู่อาหารตามประเภทสินค้าจริงควบคู่กับระดับพลังงาน (ไม่จัดขนมขบเคี้ยวเป็นอาหารมื้อหลัก)
  String _getCalorieCategory(double kcal) {
    final cat = _currentItem.effectiveCategory;
    if (cat == 'snack') {
      if (kcal <= 150) {
        return 'ของว่าง / ขนมขบเคี้ยว (พลังงานเบาๆ)';
      } else if (kcal <= 300) {
        return 'ของว่าง / ขนมขบเคี้ยว (พลังงานปานกลาง)';
      } else {
        return 'ของว่าง / ขนมขบเคี้ยว (พลังงานสูง ควรแบ่งบริโภค)';
      }
    }

    if (kcal <= 200) {
      return 'อาหารว่าง / เครื่องดื่ม (พลังงานเบาๆ)';
    } else if (_unitLabel == 'มล.' || cat == 'beverage') {
      return kcal <= 350
          ? 'เครื่องดื่ม / นม (พลังงานปานกลาง)'
          : 'เครื่องดื่มพลังงานสูง (ควรระวังน้ำตาล)';
    } else if (kcal <= 550) {
      return 'อาหารมื้อหลัก (พลังงานปานกลาง)';
    } else {
      return 'อาหารพลังงานสูง (ควรระวังปริมาณ)';
    }
  }

  /// 4. Calculated Energy Card with Flame Circular Gauge 🔥 (Figma Screen 5)
  Widget _buildCalculatedEnergyCard({
    required double calories,
    required double dailyTarget,
    required double caloriePercent,
    required double calorieProgress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Calories & Daily %
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'พลังงานที่คำนวณได้',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        calories.toStringAsFixed(0),
                        style: AppTypography.heading1.copyWith(
                          fontSize: 42,
                          color: const Color(0xFF1E1B4B),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'กิโลแคลอรี่ (kcal)',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'คิดเป็น ${caloriePercent.toStringAsFixed(1)}% ของความต้องการพลังงานต่อวัน (${dailyTarget.toStringAsFixed(0)} kcal)',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getCalorieCategory(calories),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'เหลือโควตาพลังงานสำหรับวันนี้อีก ${(dailyTarget - calories).clamp(0, dailyTarget).toInt()} kcal',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
                if (_currentItem.servingsPerContainer > 1.0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'คุณค่าทางโภชนาการต่อ 1 ซอง (ควรแบ่งกินประมาณ ${_currentItem.servingsPerContainer.toStringAsFixed(0)} ครั้ง • ครั้งละ ${(calories / _currentItem.servingsPerContainer).round()} kcal)',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF0369A1),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right: Circular Gauge with Flame Icon 🔥
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0.0, end: calorieProgress),
                    builder: (context, val, _) {
                      return CustomPaint(
                        painter: _FlameRingPainter(
                          progress: val,
                          primaryColor: AppColors.primary,
                          trackColor: const Color(0xFFEDE9FE),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. 2x2 Macronutrient Colored Cards (โปรตีน, คาร์โบไฮเดรต, ไขมันรวม, น้ำตาล)
  Widget _buildMacronutrientsSection({
    required double protein,
    required double carbs,
    required double fat,
    required double sugar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สารอาหารหลัก (Macronutrients)',
          style: AppTypography.heading3.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // 2x2 Grid Layout matching Figma Screen 5
        Row(
          children: [
            // Top Left: Protein (Green)
            Expanded(
              child: _MacroGridCard(
                label: 'โปรตีน (Protein)',
                grams: protein,
                rdiGoal: 50.0,
                color: const Color(0xFF10B981), // Emerald Green
                bgColor: const Color(0xFFD1FAE5),
                textColor: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 12),
            // Top Right: Carbs (Sky Blue)
            Expanded(
              child: _MacroGridCard(
                label: 'คาร์โบไฮเดรต (Carbohydrates)',
                grams: carbs,
                rdiGoal: 300.0,
                color: const Color(0xFF0284C7), // Sky Blue
                bgColor: const Color(0xFFE0F2FE),
                textColor: const Color(0xFF0369A1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Bottom Left: Fat (Coral/Red)
            Expanded(
              child: _MacroGridCard(
                label: 'ไขมันรวม (Total Fat)',
                grams: fat,
                rdiGoal: 65.0,
                color: const Color(0xFFEF4444), // Coral Red
                bgColor: const Color(0xFFFEE2E2),
                textColor: const Color(0xFF991B1B),
              ),
            ),
            const SizedBox(width: 12),
            // Bottom Right: Sugar (Purple)
            Expanded(
              child: _MacroGridCard(
                label: 'น้ำตาล (Sugar)',
                grams: sugar,
                rdiGoal: 24.0,
                color: const Color(0xFF8B5CF6), // Purple
                bgColor: const Color(0xFFF3E8FF),
                textColor: const Color(0xFF5B21B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Energy distribution ratio
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สัดส่วนการกระจายพลังงาน (Energy Ratio)',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: ((protein * 4) / (((protein * 4) + (carbs * 4) + (fat * 9)) == 0 ? 1 : ((protein * 4) + (carbs * 4) + (fat * 9))) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                      Expanded(
                        flex: ((carbs * 4) / (((protein * 4) + (carbs * 4) + (fat * 9)) == 0 ? 1 : ((protein * 4) + (carbs * 4) + (fat * 9))) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF0284C7)),
                      ),
                      Expanded(
                        flex: ((fat * 9) / (((protein * 4) + (carbs * 4) + (fat * 9)) == 0 ? 1 : ((protein * 4) + (carbs * 4) + (fat * 9))) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text('โปรตีน ${(protein * 4).toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  Text('คาร์โบไฮเดรต ${(carbs * 4).toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                  Text('ไขมัน ${(fat * 9).toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 6. Micronutrients List (ใยอาหาร, โซเดียม, ไขมันอิ่มตัว)
  Widget _buildMicronutrientsCard({
    required double fiber,
    required double sodium,
    required double saturatedFat,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMicroRow(
            icon: Icons.grain_rounded,
            iconColor: const Color(0xFF8B5CF6),
            label: 'ใยอาหาร (Fiber)',
            value: '${fiber.toStringAsFixed(1)} g',
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildMicroRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0284C7),
            label: 'โซเดียม (Sodium)',
            value: '${sodium.toStringAsFixed(0)} mg',
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildMicroRow(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFFD97706),
            label: 'ไขมันอิ่มตัว (Saturated Fat)',
            value: '${saturatedFat.toStringAsFixed(1)} g',
          ),
        ],
      ),
    );
  }

  Widget _buildMicroRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.heading3.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      ],
    );
  }

  /// 7. Local Database & Firebase Cloud Sync Status Card
  Widget _buildDatabaseSyncStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'บันทึกในเครื่อง (SQLite/Hive)',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: const Color(0xFFCBD5E1),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'พร้อมซิงค์ Firebase',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 7.5. ปุ่มจัดการข้อมูลโภชนาการ: แก้ไขข้อมูลด้วยตนเอง (Manual Override), รายงานข้อมูลผิดพลาด (Report), และอัปเดตฐานข้อมูลทั้งหมด (Bulk Refresh)
  Widget _buildDataManagementActionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'จัดการความถูกต้องของข้อมูลโภชนาการ',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              if (_currentItem.isUserEdited)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'is_user_edited: true',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showEditNutritionBottomSheet,
                  icon: const Icon(Icons.edit_note_rounded, size: 17, color: AppColors.primary),
                  label: const Text(
                    'แก้ไขข้อมูลโภชนาการ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showReportDataDialog,
                  icon: Icon(
                    _currentItem.isReported ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                    size: 16,
                    color: const Color(0xFFEA580C),
                  ),
                  label: Text(
                    _currentItem.isReported ? 'ส่งรายงานแล้ว' : 'รายงานข้อมูลผิดพลาด',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isRefreshing ? null : _bulkRefreshAllFoodItems,
              icon: const Icon(Icons.published_with_changes_rounded, size: 15, color: Color(0xFF475569)),
              label: const Text(
                'อัปเดตฐานข้อมูลอาหารทั้งหมดในเครื่อง (ข้ามรายการที่แก้ไขเอง)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 8. AI Nutritional Insights (วิเคราะห์ตามค่าสารอาหารจริงของสินค้า)
  Widget _buildAiInsightCard({
    required double calories,
    required double protein,
    required double fat,
    required double sugar,
    required double sodium,
  }) {
    String insightText;
    if (sodium >= 600) {
      insightText =
          'มีปริมาณโซเดียมค่อนข้างสูง (${sodium.toStringAsFixed(0)} mg) แนะนำให้ดื่มน้ำเปล่าตามมากๆ และหลีกเลี่ยงการเติมเครื่องปรุงรสเพิ่มในมื้อนี้';
    } else if (sugar >= 16) {
      insightText =
          'มีน้ำตาล ${sugar.toStringAsFixed(1)} กรัม คิดเป็นสัดส่วนที่สูงของโควต้าต่อวัน แนะนำให้แบ่งดื่มหรือลดของหวานอื่นในวันเดียวกัน';
    } else if (fat >= 12) {
      insightText =
          'ให้พลังงาน ${calories.toStringAsFixed(0)} kcal และไขมัน ${fat.toStringAsFixed(1)} กรัม แนะนำให้แบ่งรับประทานตามหน่วยบริโภคบนฉลาก หรือทานคู่กับมื้ออาหารที่มีโปรตีนและใยอาหาร';
    } else if (protein >= 10) {
      insightText =
          'เป็นแหล่งโปรตีนที่ดี (${protein.toStringAsFixed(1)} กรัม) ช่วยเสริมสร้างกล้ามเนื้อและทำให้อิ่มท้องนาน เหมาะสำหรับมื้อว่างหรือหลังออกกำลังกาย';
    } else {
      insightText =
          'ให้พลังงาน ${calories.toStringAsFixed(0)} kcal (เกรดโภชนาการ ${_currentItem.nutriScore ?? "B"}) สัดส่วนน้ำตาลและโซเดียมอยู่ในเกณฑ์ที่เหมาะสมต่อการบริโภคระหว่างวัน';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บทวิเคราะห์จาก Gemini AI',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 9. Rescan Barcode Bar
  Widget _buildRescanBarcodeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF475569)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สแกนบาร์โค้ดอื่น',
                  style: AppTypography.chipText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'ตรวจจับรหัส UPC / EAN ทันที',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'สแกน',
                    style: AppTypography.chipText.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF1E1B4B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 10. Save to Daily Food Log CTA Button (บันทึกมื้ออาหารลงไดอารี่)
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
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
          final currentW = _effectiveWeight;
          final adjustedServingLabel = _customWeightGrams != null
              ? '${currentW.toStringAsFixed(currentW == currentW.roundToDouble() ? 0 : 1)} $_unitLabel'
              : '${_currentItem.servingSize} (x${_portionMultiplier.toStringAsFixed(1).replaceAll('.0', '')})';

          final adjustedItem = _portionMultiplier != 1.0
              ? _currentItem.copyWith(
                  calories: _currentItem.calories * _portionMultiplier,
                  protein: _currentItem.protein * _portionMultiplier,
                  carbohydrates: _currentItem.carbohydrates * _portionMultiplier,
                  fat: _currentItem.fat * _portionMultiplier,
                  sugar: _currentItem.sugar * _portionMultiplier,
                  fiber: _currentItem.fiber * _portionMultiplier,
                  saturatedFat: _currentItem.saturatedFat * _portionMultiplier,
                  sodium: _currentItem.sodium * _portionMultiplier,
                  servingSize: adjustedServingLabel,
                  scannedAt: DateTime.now(),
                )
              : _currentItem;

          final provider = Provider.of<NutritionProvider>(context, listen: false);
          provider.saveFoodItem(adjustedItem);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'บันทึก "${_currentItem.name}" ในบันทึกอาหารแล้ว',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 20),
        label: Text(
          'บันทึกลงสมุดบันทึกอาหารประจำวัน',
          style: AppTypography.buttonText.copyWith(fontSize: 15),
        ),
      ),
    );
  }
}

/// 2x2 Macronutrient Grid Card with Custom Color & Progress Bar
class _MacroGridCard extends StatelessWidget {
  final String label;
  final double grams;
  final double rdiGoal;
  final Color color;
  final Color bgColor;
  final Color textColor;

  const _MacroGridCard({
    required this.label,
    required this.grams,
    required this.rdiGoal,
    required this.color,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = rdiGoal > 0 ? (grams / rdiGoal * 100.0) : 0.0;
    final double progress = (grams / rdiGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${grams.toStringAsFixed(1)} กรัม',
            style: AppTypography.heading2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rdiGoal == 24.0
                ? '${percent.toStringAsFixed(1)}% ของเกณฑ์ที่แนะนำต่อวัน (ไม่เกิน 24 กรัม (6 ช้อนชา))'
                : '${percent.toStringAsFixed(1)}% ของเกณฑ์ที่แนะนำต่อวัน (${rdiGoal.toStringAsFixed(0)} กรัม)',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 9.5,
              color: textColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Flame Circular Ring Gauge Painter
class _FlameRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _FlameRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlameRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
