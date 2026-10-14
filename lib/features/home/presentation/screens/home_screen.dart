import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_food_camera_screen.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';
import 'package:nutrisnap/features/scanner/presentation/screens/barcode_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'สวัสดีตอนเช้า';
    } else if (hour < 17) {
      return 'สวัสดีตอนบ่าย';
    } else {
      return 'สวัสดีตอนเย็น';
    }
  }

  String _getThaiDateString() {
    final now = DateTime.now();
    const days = [
      'วันจันทร์',
      'วันอังคาร',
      'วันพุธ',
      'วันพฤหัสบดี',
      'วันศุกร์',
      'วันเสาร์',
      'วันอาทิตย์'
    ];
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
      'ธ.ค.'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayNameที่ ${now.day} $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final displayName = user != null && user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user?.isAnonymous == true ? 'ผู้ใช้ทั่วไป' : 'ปรียาภรณ์');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar
              _buildTopBar(context),
              const SizedBox(height: 18),

              // 2. Greeting & Status
              _buildGreetingHeader(displayName),
              const SizedBox(height: 20),

              // 3. Nutrition Summary Card
              _buildSummaryCard(context),
              const SizedBox(height: 18),

              // 4. Action Card 1: Barcode Scanner
              _buildActionCard(
                context: context,
                iconData: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: AppColors.primary,
                title: 'สแกนบาร์โค้ดผลิตภัณฑ์',
                subtitle: 'เชื่อมต่อ Open Food Facts API',
                subtitlePrefixIcon: Icons.circle,
                subtitlePrefixColor: AppColors.primary,
                buttonText: 'สแกน',
                buttonIcon: Icons.qr_code_2_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 5. Action Card 2: AI Food Camera
              _buildActionCard(
                context: context,
                iconData: Icons.center_focus_strong_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: AppColors.primary,
                title: 'วิเคราะห์ภาพอาหารด้วย AI',
                subtitle: 'เทคโนโลยี Gemini AI Vision',
                subtitlePrefixIcon: Icons.auto_awesome,
                subtitlePrefixColor: AppColors.primary,
                buttonText: 'ถ่ายภาพ',
                buttonIcon: Icons.camera_alt_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AiFoodCameraScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // 6. Recent Meals Section
              _buildRecentMealsHeader(context),
              const SizedBox(height: 12),
              _buildRecentMealsList(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand Logo & Title
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriSnap',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'หน้าหลัก',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Action Icons
        Row(
          children: [
            // Cloud Sync Icon Button
            IconButton(
              icon: const Icon(
                Icons.sync_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              onPressed: () async {
                final ok = await context.read<NutritionProvider>().syncCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'ซิงค์ข้อมูลกับ Firestore เรียบร้อยแล้ว' : 'ซิงค์ข้อมูลไม่สำเร็จ',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: ok ? AppColors.success : AppColors.error,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 4),

            // Profile Avatar Button
            GestureDetector(
              onTap: () => onNavigateTab?.call(3), // Navigate to Profile Tab
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreetingHeader(String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${_getGreeting()}, $displayName ! 👋',
                style: AppTypography.heading1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ซิงค์คลาวด์แล้ว',
                    style: AppTypography.chipText.copyWith(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getThaiDateString(),
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final recentScans = context.watch<NutritionProvider>().recentScans;
    final mealsCount = recentScans.length;
    final totalCalories = recentScans.fold<double>(0, (sum, item) => sum + item.calories).toInt();
    final totalProtein = recentScans.fold<double>(0, (sum, item) => sum + item.protein).toInt();
    final totalCarbs = recentScans.fold<double>(0, (sum, item) => sum + item.carbohydrates).toInt();
    final totalFat = recentScans.fold<double>(0, (sum, item) => sum + item.fat).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Title + Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'มื้ออาหารที่บันทึกวันนี้',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B4B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D5FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$mealsCount มื้อ',
                  style: AppTypography.chipText.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calorie display
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                totalCalories >= 1000
                    ? '${(totalCalories ~/ 1000)},${(totalCalories % 1000).toString().padLeft(3, '0')}'
                    : '$totalCalories',
                style: AppTypography.heading1.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                'แคลอรี่ที่บันทึก',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macronutrient Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroChip(
                label: 'โปรตีน $totalProteinก.',
                dotColor: AppColors.primary,
              ),
              _buildMacroChip(
                label: 'คาร์บ $totalCarbsก.',
                dotColor: const Color(0xFF0284C7),
              ),
              _buildMacroChip(
                label: 'ไขมัน $totalFatก.',
                dotColor: const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.chipText.copyWith(
              color: const Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData iconData,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required IconData subtitlePrefixIcon,
    required Color subtitlePrefixColor,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(iconData, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading3.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      subtitlePrefixIcon,
                      size: 9,
                      color: subtitlePrefixColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Button
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: Icon(buttonIcon, color: Colors.white, size: 16),
              label: Text(
                buttonText,
                style: AppTypography.chipText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMealsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'มื้ออาหารล่าสุด',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onNavigateTab?.call(1), // Navigate to History Tab
          child: Text(
            'ดูทั้งหมด >',
            style: AppTypography.chipText.copyWith(
              color: AppColors.primary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMealsList(BuildContext context) {
    final recentScans = context.watch<NutritionProvider>().recentScans;

    if (recentScans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีมื้ออาหารที่บันทึกวันนี้',
              style: AppTypography.heading3.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'สแกนบาร์โค้ดหรือถ่ายภาพอาหารเพื่อเริ่มต้นติดตามสารอาหารของคุณ',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final displayItems = recentScans.take(5).toList();

    return Column(
      children: displayItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NutritionDetailScreen(item: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Meal Image / Placeholder Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: Colors.white,
                        child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _buildMealIcon(item),
                              )
                            : _buildMealIcon(item),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Meal Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.heading3.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1B4B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),

                          // Tag: Barcode or AI Estimate
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.source == 'barcode_scan'
                                      ? Icons.qr_code_rounded
                                      : Icons.auto_awesome,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.source == 'barcode_scan'
                                        ? 'บาร์โค้ด'
                                        : 'AI ประมาณการ',
                                    style: AppTypography.chipText.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Calories & Protein info
                          Text(
                            '${item.calories.toInt()} แคล  •  โปรตีน ${item.protein.toInt()}ก.',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right time text if available
                    Text(
                      _getRelativeTimeString(item.scannedAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealIcon(FoodItem item) {
    IconData iconData = Icons.lunch_dining_rounded;
    if (item.name.contains('โยเกิร์ต')) {
      iconData = Icons.icecream_rounded;
    } else if (item.name.contains('สลัด')) {
      iconData = Icons.eco_rounded;
    } else if (item.name.contains('ขนมปัง')) {
      iconData = Icons.breakfast_dining_rounded;
    }
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Icon(iconData, color: AppColors.primary, size: 28),
      ),
    );
  }

  String _getRelativeTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inHours < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.';
    } else if (difference.inDays < 2) {
      return 'เมื่อวานนี้';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
