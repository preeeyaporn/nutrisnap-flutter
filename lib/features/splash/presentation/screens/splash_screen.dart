import 'package:flutter/material.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/auth/presentation/screens/login_screen.dart';
import 'package:nutrisnap/features/onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E8FF), // Light violet glow at top
              Color(0xFFFAF5FF),
              Colors.white,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Top Squircle App Icon (Figma Screen 1)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6D28D9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer scanning bracket corners
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CustomPaint(
                                      painter: _ScannerBracketPainter(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Clock / Timer inside scanner
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Pill Badge: "● ปัญญาประดิษฐ์ด้านโภชนาการ"
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
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
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'ปัญญาประดิษฐ์ด้านโภชนาการ',
                                      style: AppTypography.chipText.copyWith(
                                        color: const Color(0xFF7C3AED),
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // App Brand Name: NutriSnap
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Nutri',
                                  style: AppTypography.heading1.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1B4B),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Snap',
                                  style: AppTypography.heading1.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle: "สแกน. • วิเคราะห์. • บันทึก."
                          RichText(
                            text: TextSpan(
                              style: AppTypography.heading3.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'สแกน. • วิเคราะห์. ',
                                  style: TextStyle(color: Color(0xFF1F2937)),
                                ),
                                const TextSpan(
                                  text: '• บันทึก.',
                                  style: TextStyle(color: Color(0xFF7C3AED)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline: "โภชนาการอัจฉริยะ ปลายนิ้วสัมผัส"
                          Text(
                            'โภชนาการอัจฉริยะ ปลายนิ้วสัมผัส',
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 3 Feature Cards Row (Figma Screen 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFeatureCard(
                                icon: Icons.camera_alt_outlined,
                                label: 'สแกนทันใจ',
                              ),
                              _buildFeatureCard(
                                icon: Icons.bolt_rounded,
                                label: 'เรียลไทม์',
                              ),
                              _buildFeatureCard(
                                icon: Icons.show_chart_rounded,
                                label: 'แม่นยำ',
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Progress Bar (Figma Screen 1)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 5,
                              width: double.infinity,
                              color: const Color(0xFFEDE9FE),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF7C3AED),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Powered by badge: "ขับเคลื่อนโดย Open Food Facts & Gemini API"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.apps_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'ขับเคลื่อนโดย Open Food Facts & Gemini API',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF4B5563),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(flex: 2),

                          // Primary CTA Button: "เริ่มต้นใช้งาน ->"
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF6D28D9),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _navigateToOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'เริ่มต้นใช้งาน',
                                      style: AppTypography.buttonText.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _navigateToLogin,
                            child: Text.rich(
                              TextSpan(
                                text: 'มีบัญชีอยู่แล้วใช่หรือไม่? ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutralSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'เข้าสู่ระบบ',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Bottom home indicator bar
                          Container(
                            width: 140,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the 4 corner viewfinder brackets inside the splash icon
class _ScannerBracketPainter extends CustomPainter {
  final Color color;

  _ScannerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 12.0;

    // Top Left
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
