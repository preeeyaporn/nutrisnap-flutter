import 'package:flutter/material.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingStepData> _steps = const [
    _OnboardingStepData(
      subtitle: 'เพื่อนคู่คิดด้านสุขภาพของคุณ',
      title: 'วิเคราะห์สารอาหารอย่างชาญฉลาด',
      description:
          'เปลี่ยนการรับรู้พลังงานในอาหารในแต่ละวัน ผ่านการสแกนด้วยสายตาและการวิเคราะห์ที่แม่นยำ',
      cardBadge: 'ฐานข้อมูล Open Food Facts API',
      cardActionText: 'ค้นหาทันที',
      featureIcon: Icons.qr_code_scanner_rounded,
      featureTitle: 'เครื่องสแกนบาร์โค้ดอัจฉริยะ',
      featureDescription:
          'สแกนบรรจุภัณฑ์ในเสี้ยววินาที เพื่อดึงข้อมูลโภชนาการที่ได้รับการตรวจสอบแล้ว โดยไม่ต้องเดาเอง',
      imageAsset: 'assets/images/screen_onboarding.png',
      nutrients: [
        _NutrientChip(label: 'แคลอรี่', color: AppColors.calorieColor, bg: AppColors.calorieBg),
        _NutrientChip(label: 'โปรตีน', color: AppColors.proteinColor, bg: AppColors.proteinBg),
        _NutrientChip(label: 'คาร์โบไฮเดรต', color: AppColors.carbsColor, bg: AppColors.carbsBg),
        _NutrientChip(label: 'ไขมัน', color: AppColors.fatColor, bg: AppColors.fatBg),
        _NutrientChip(label: 'น้ำตาล', color: AppColors.sugarColor, bg: AppColors.sugarBg),
      ],
    ),
    _OnboardingStepData(
      subtitle: 'เทคโนโลยี AI ขั้นสูง',
      title: 'ถ่ายภาพเพื่อวิเคราะห์ด้วย Gemini AI',
      description:
          'ส่องกล้องไปยังจานอาหาร ระบบจะประเมินชนิด สัดส่วน และแคลอรี่ให้คุณอัตโนมัติด้วยโมเดล Gemini 1.5 Flash Vision',
      cardBadge: 'Gemini 1.5 Flash Vision',
      cardActionText: 'ตรวจจับสด',
      featureIcon: Icons.auto_awesome_rounded,
      featureTitle: 'AI จำแนกอาหารสดและเมนูปรุงสุก',
      featureDescription:
          'ระบุส่วนผสม ประเมินพลังงาน พร้อมให้คำแนะนำโภชนาการที่เหมาะกับร่างกายของคุณแบบเฉพาะเจาะจง',
      imageAsset: 'assets/images/screen_camera.png',
      nutrients: [
        _NutrientChip(label: 'พลังงานรวม', color: AppColors.calorieColor, bg: AppColors.calorieBg),
        _NutrientChip(label: 'โปรตีนแท้', color: AppColors.proteinColor, bg: AppColors.proteinBg),
        _NutrientChip(label: 'วิตามิน & แร่ธาตุ', color: AppColors.success, bg: AppColors.successLight),
        _NutrientChip(label: 'ไฟเบอร์', color: AppColors.carbsColor, bg: AppColors.carbsBg),
      ],
    ),
    _OnboardingStepData(
      subtitle: 'สุขภาพดีเริ่มต้นที่คุณ',
      title: 'บันทึกและซิงค์ข้อมูลผ่านคลาวด์',
      description:
          'เชื่อมต่อ Hive Local Database และ Cloud Firestore เก็บประวัติการสแกนและคำนวณโภชนาการรายวันอย่างปลอดภัย',
      cardBadge: 'ซิงค์ข้อมูลเรียลไทม์',
      cardActionText: 'พร้อมใช้งาน',
      featureIcon: Icons.cloud_done_rounded,
      featureTitle: 'ระบบความปลอดภัยและการจัดเก็บระดับโปร',
      featureDescription:
          'เข้าถึงข้อมูลได้ทุกที่แม้ไม่มีสัญญาณอินเทอร์เน็ตด้วยระบบแคชท้องถิ่น Hive และซิงค์ขึ้น Firestore ทันทีเมื่อต่อเน็ต',
      imageAsset: 'assets/images/screen_barcode.png',
      nutrients: [
        _NutrientChip(label: 'เกรด A', color: AppColors.proteinColor, bg: AppColors.proteinBg),
        _NutrientChip(label: 'บันทึกอัตโนมัติ', color: AppColors.calorieColor, bg: AppColors.calorieBg),
        _NutrientChip(label: 'ปลอดภัย 100%', color: AppColors.success, bg: AppColors.successLight),
      ],
    ),
  ];

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Figma Screen 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NutriSnap',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),

                  // Skip Button Pill
                  GestureDetector(
                    onTap: _finishOnboarding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ข้าม',
                        style: AppTypography.chipText.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView of Onboarding Steps
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Subtitle: "เพื่อนคู่คิดด้านสุขภาพของคุณ"
                        Center(
                          child: Text(
                            step.subtitle,
                            style: AppTypography.subtitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title: "วิเคราะห์สารอาหารอย่างชาญฉลาด"
                        Center(
                          child: Text(
                            step.title,
                            style: AppTypography.heading2.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1B4B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Center(
                          child: Text(
                            step.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF64748B),
                              height: 1.45,
                              fontSize: 13.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Main Feature Card (Figma Screen 2)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Image with Overlays
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(26),
                                  topRight: Radius.circular(26),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 190,
                                      width: double.infinity,
                                      color: const Color(0xFFF1F5F9),
                                      child: Image.asset(
                                        step.imageAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          color: const Color(0xFFE2E8F0),
                                          child: const Icon(
                                            Icons.image_search_rounded,
                                            size: 48,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Top Left Badge: "● ฐานข้อมูล Open Food Facts API"
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(16),
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
                                              step.cardBadge,
                                              style: AppTypography.chipText.copyWith(
                                                color: const Color(0xFF1E293B),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom Right Pill: "ค้นหาทันที"
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          step.cardActionText,
                                          style: AppTypography.chipText.copyWith(
                                            color: const Color(0xFF334155),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom Details inside Card
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Feature Title Row
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3E8FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            step.featureIcon,
                                            color: const Color(0xFF7C3AED),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            step.featureTitle,
                                            style: AppTypography.heading3.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Description
                                    Text(
                                      step.featureDescription,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFF64748B),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Nutrient Pills Wrap (Figma Screen 2)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: step.nutrients.map((n) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: n.bg,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: n.color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                n.label,
                                                style: AppTypography.chipText.copyWith(
                                                  color: n.color,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Carousel Dots + CTA (Figma Screen 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  // Page Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  // Button: "ฟีเจอร์ถัดไป ->"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _steps.length - 1
                                  ? 'เริ่มต้นใช้งานทันที'
                                  : 'ฟีเจอร์ถัดไป',
                              style: AppTypography.buttonText.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // "ขั้นตอน 1 จาก 3"
                  Text(
                    'ขั้นตอน ${_currentPage + 1} จาก ${_steps.length}',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepData {
  final String subtitle;
  final String title;
  final String description;
  final String cardBadge;
  final String cardActionText;
  final IconData featureIcon;
  final String featureTitle;
  final String featureDescription;
  final String imageAsset;
  final List<_NutrientChip> nutrients;

  const _OnboardingStepData({
    required this.subtitle,
    required this.title,
    required this.description,
    required this.cardBadge,
    required this.cardActionText,
    required this.featureIcon,
    required this.featureTitle,
    required this.featureDescription,
    required this.imageAsset,
    required this.nutrients,
  });
}

class _NutrientChip {
  final String label;
  final Color color;
  final Color bg;

  const _NutrientChip({
    required this.label,
    required this.color,
    required this.bg,
  });
}
