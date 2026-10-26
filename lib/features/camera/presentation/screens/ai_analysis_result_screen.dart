import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/meal_detail_screen.dart';

/// Screen 8 — AI Analysis Result (TH)
/// Shows detailed nutrition calculations from Gemini AI Vision
/// Includes interactive re-calculation if the detected food is not what the user ordered.
class AiAnalysisResultScreen extends StatefulWidget {
  final NutritionAnalysisResult analysis;
  final List<int>? imageBytes;

  const AiAnalysisResultScreen({
    super.key,
    required this.analysis,
    this.imageBytes,
  });

  @override
  State<AiAnalysisResultScreen> createState() => _AiAnalysisResultScreenState();
}

class _AiAnalysisResultScreenState extends State<AiAnalysisResultScreen> {
  late NutritionAnalysisResult _currentAnalysis;
  late TextEditingController _correctionController;
  bool _isRecalculating = false;
  bool _isCorrectionExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.analysis;
    _correctionController = TextEditingController(text: _currentAnalysis.foodName);
  }

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _handleRecalculate() async {
    final correctedText = _correctionController.text.trim();
    if (correctedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่ออาหารที่ถูกต้อง')),
      );
      return;
    }

    setState(() {
      _isRecalculating = true;
    });

    final provider = context.read<NutritionProvider>();
    final success = await provider.recalculateWithFoodCorrection(
      correctedFoodName: correctedText,
      imageBytes: widget.imageBytes,
    );

    if (mounted) {
      setState(() {
        _isRecalculating = false;
        if (success && provider.currentAiAnalysis != null) {
          _currentAnalysis = provider.currentAiAnalysis!;
          _isCorrectionExpanded = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gemini คำนวณสารอาหารใหม่สำหรับ "$correctedText" เรียบร้อยแล้ว',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSaveAndNavigate() async {
    final provider = context.read<NutritionProvider>();
    final foodItem = await provider.saveCurrentAiMeal(customAnalysis: _currentAnalysis);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF7C3AED),
        content: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'บันทึกมื้ออาหาร "${_currentAnalysis.foodName}" ลงไดอารี่แล้ว',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          item: foodItem,
          analysisResult: _currentAnalysis,
          imageBytes: widget.imageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = _currentAnalysis.calories;
    final protein = _currentAnalysis.protein;
    final carbs = _currentAnalysis.carbohydrates;
    final fat = _currentAnalysis.fat;
    final confidencePercent = (_currentAnalysis.confidence * 100).toInt();

    final totalMacros = (protein * 4) + (carbs * 4) + (fat * 9);
    final proteinRatio = totalMacros > 0 ? (protein * 4) / totalMacros : 0.25;
    final carbsRatio = totalMacros > 0 ? (carbs * 4) / totalMacros : 0.48;
    final fatRatio = totalMacros > 0 ? (fat * 9) / totalMacros : 0.27;

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
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Badges Row: "✦ ความแม่นยำ 94% • Gemini Vision API" + "● ตรวจสอบแล้ว"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ความแม่นยำ $confidencePercent% • Gemini Vision API',
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ตรวจสอบแล้ว',
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
            const SizedBox(height: 12),

            // Food Image Card (Matching Figma Screen 8)
            _buildFoodImageCard(),
            const SizedBox(height: 14),

            // User Correction Section (User requirement: หากไม่ใช่อาหารที่สั่ง ให้มีช่องกรอกเพื่อให้ Gemini คำนวณใหม่)
            _buildCorrectionCard(),
            const SizedBox(height: 14),

            // Warning Banner (Peach/Orange background from Figma Screen 8)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFFEA580C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ข้อมูลโภชนาการเป็นค่าประมาณ ค่าจริงอาจแตกต่างกันไปตามปริมาณน้ำมันปรุงอาหาร อัตราส่วนเครื่องปรุง และสัดส่วนวัตถุดิบ',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF9A3412),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calories & Macros Card (Figma Screen 8)
            _buildCaloriesAndMacrosCard(
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              proteinRatio: proteinRatio,
              carbsRatio: carbsRatio,
              fatRatio: fatRatio,
            ),
            const SizedBox(height: 20),

            // Identified Ingredients Section (ส่วนผสมที่ระบุได้ 4 รายการ)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ส่วนผสมที่ระบุได้',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentAnalysis.detectedIngredients.length} รายการ',
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
              children: _currentAnalysis.detectedIngredients.map((ingredient) {
                return _buildIngredientChip(ingredient);
              }).toList(),
            ),
            const SizedBox(height: 26),

            // Action Buttons Row (Figma Screen 8)
            // 1. Primary Button: บันทึกมื้ออาหารลงไดอารี่ [จัดเก็บในเครื่อง + คลาวด์]
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                onPressed: _handleSaveAndNavigate,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'บันทึกมื้ออาหารลงไดอารี่',
                        style: AppTypography.buttonText.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'จัดเก็บในเครื่อง + คลาวด์',
                          style: AppTypography.chipText.copyWith(
                            color: Colors.white,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Secondary Button: ถ่ายภาพใหม่อีกครั้ง
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF475569)),
                label: Text(
                  'ถ่ายภาพใหม่อีกครั้ง',
                  style: AppTypography.buttonText.copyWith(
                    color: const Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImageCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Captured image or high quality fallback asset
            _buildImageWidget(),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top-left badge: "ผลการวิเคราะห์โดย AI"
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ผลวิเคราะห์ Gemini AI',
                      style: AppTypography.chipText.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info: Food name & Tag
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.dinner_dining_rounded,
                            color: Color(0xFF7C3AED), size: 14),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'อาหารที่ตรวจพบ: ${_currentAnalysis.foodName}',
                            style: AppTypography.chipText.copyWith(
                              color: const Color(0xFF4C1D95),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentAnalysis.foodName,
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white70, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'ถ่ายภาพเมื่อสักครู่',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                        ),
                      ),
                      if (_currentAnalysis.userCorrection != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'แก้ไขแล้ว',
                            style: AppTypography.chipText.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildImageWidget() {
    if (widget.imageBytes != null && widget.imageBytes!.length > 200) {
      try {
        return Image.memory(
          Uint8List.fromList(widget.imageBytes!),
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    return Image.asset(
      'assets/images/screen_camera_guide.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF334155),
        child: const Center(
          child: Icon(Icons.restaurant_rounded, color: Colors.white54, size: 54),
        ),
      ),
    );
  }

  Widget _buildCorrectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isCorrectionExpanded
              ? const Color(0xFF7C3AED)
              : const Color(0xFFE2E8F0),
          width: _isCorrectionExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _isCorrectionExpanded = !_isCorrectionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ไม่ใช่เมนูที่คุณสั่งใช่ไหม?',
                          style: AppTypography.heading3.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isCorrectionExpanded
                              ? 'ระบุชื่ออาหารจริงเพื่อให้ Gemini คำนวณใหม่'
                              : 'แตะที่นี่เพื่อเปลี่ยนเมนูและคำนวณสารอาหารใหม่',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isCorrectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
          ),

          if (_isCorrectionExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'พิมพ์ชื่ออาหารจริงที่คุณสั่ง:',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _correctionController,
                    decoration: InputDecoration(
                      hintText: 'เช่น ข้าวกะเพราไก่ไข่ดาว, ผัดไทยกุ้งสด, ข้าวมันไก่...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.restaurant_menu_rounded,
                          color: Color(0xFF7C3AED), size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _correctionController.clear(),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isRecalculating ? null : _handleRecalculate,
                      icon: _isRecalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _isRecalculating
                            ? 'Gemini กำลังคำนวณใหม่...'
                            : 'ให้ Gemini คำนวณสารอาหารใหม่',
                        style: AppTypography.buttonText.copyWith(fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaloriesAndMacrosCard({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double proteinRatio,
    required double carbsRatio,
    required double fatRatio,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: "พลังงานรวมโดยประมาณ" + Big number "560 กิโลแคลอรี่" + Ring icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'พลังงานรวมโดยประมาณ',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        calories.toInt().toString(),
                        style: AppTypography.heading1.copyWith(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'กิโลแคลอรี่',
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${calories.toInt()} kcal',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Circular flame badge matching Screen 8
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C3AED),
                    width: 4,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFF7C3AED),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Colored multi-segment progress bar (Purple - Blue - Salmon)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  Expanded(
                    flex: (proteinRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: const Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (carbsRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: const Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (fatRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: const Color(0xFFFB7185)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3 Columns: Protein / Carbs / Fat
          Row(
            children: [
              Expanded(
                child: _buildMacroBox(
                  label: 'โปรตีน',
                  grams: '${protein.toInt()} ก.',
                  percentage: '${(proteinRatio * 100).round()}%',
                  indicatorColor: const Color(0xFF7C3AED),
                  altText: '${protein.toInt()}g',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroBox(
                  label: 'คาร์โบไฮเดรต',
                  grams: '${carbs.toInt()} ก.',
                  percentage: '${(carbsRatio * 100).round()}%',
                  indicatorColor: const Color(0xFF38BDF8),
                  altText: '${carbs.toInt()}g',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroBox(
                  label: 'ไขมัน',
                  grams: '${fat.toInt()} ก.',
                  percentage: '${(fatRatio * 100).round()}%',
                  indicatorColor: const Color(0xFFFB7185),
                  altText: '${fat.toInt()}g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBox({
    required String label,
    required String grams,
    required String percentage,
    required Color indicatorColor,
    required String altText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              grams,
              style: AppTypography.heading3.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percentage,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF7C3AED),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            altText,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChip(String text) {
    IconData icon = Icons.fiber_manual_record_rounded;
    if (text.contains('ไก่') || text.contains('หมู') || text.contains('เนื้อ')) {
      icon = Icons.lunch_dining_rounded;
    } else if (text.contains('ข้าว')) {
      icon = Icons.rice_bowl_rounded;
    } else if (text.contains('ไข่')) {
      icon = Icons.egg_rounded;
    } else if (text.contains('กะเพรา') || text.contains('ผัก') || text.contains('พริก')) {
      icon = Icons.eco_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.chipText.copyWith(
              color: const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
