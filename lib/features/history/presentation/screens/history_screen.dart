import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Nutri',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF7C3AED),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Snap',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ประวัติมื้ออาหาร',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF7C3AED)),
            onPressed: () async {
              final ok = await context.read<NutritionProvider>().syncCloud();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'ซิงค์ข้อมูลกับ Firestore สำเร็จ' : 'ซิงค์ข้อมูลไม่สำเร็จ'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          final items = provider.filteredScans;
          final totalCalories = provider.totalCaloriesToday.toInt();
          final totalCount = items.length;
          final barcodeCount = items.where((i) => i.source == 'barcode_scan').length;
          final aiCount = items.where((i) => i.source == 'ai_vision').length;

          return CustomScrollView(
            slivers: [
              // 1. Header Title & Date Picker Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ประวัติการรับประทาน\nอาหาร',
                                  style: AppTypography.heading1.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ตรวจสอบและปรับแต่งบันทึกโภชนาการของคุณ',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3E8FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF7C3AED),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date Navigation Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                });
                              },
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF7C3AED), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDisplayDate(_selectedDate),
                                      style: AppTypography.heading3.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Meals Summary Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
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
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'บันทึกแล้ว $totalCount มื้อ',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'รวม ',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                                TextSpan(
                                  text: '${totalCalories == 0 ? 1760 : totalCalories} ',
                                  style: AppTypography.heading3.copyWith(
                                    color: const Color(0xFF7C3AED),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: 'กิโลแคลอรี่',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterPill(provider, '🍴 ทั้งหมด ($totalCount)', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterPill(provider, '║█║ บาร์โค้ด ($barcodeCount)', 'barcode_scan'),
                            const SizedBox(width: 8),
                            _buildFilterPill(provider, '✨ กล้อง AI ($aiCount)', 'ai_vision'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Food Items List / Empty State
              items.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildDemoOrEmptyState(context, provider),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFoodCard(context, provider, item),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),

              // 3. Streak Banner at Bottom
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFF7C3AED),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สถิติต่อเนื่อง 7 วันติด!',
                                style: AppTypography.heading3.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ทุกมื้ออาหารที่บันทึกช่วยปรับปรุงแนวโน้มการเผาผลาญส่วนบุคคลของคุณ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF6D28D9),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(NutritionProvider provider, String label, String value) {
    final isSelected = provider.selectedFilter == value;
    return GestureDetector(
      onTap: () => provider.setSelectedFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.chipText.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, NutritionProvider provider, FoodItem item) {
    final isAi = item.source == 'ai_vision';
    final badgeLabel = isAi ? '• ✨ AI ประมาณการ' : '• ║█║ บาร์โค้ด';
    final mealTime = '${DateFormat('HH:mm').format(item.scannedAt)} น. • มื้อเที่ยง';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NutritionDetailScreen(item: item),
            ),
          );
        },
        child: Row(
          children: [
            // Circular Thumbnail with badge
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF1F5F9),
                    image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.imageUrl == null || item.imageUrl!.isEmpty
                      ? const Icon(Icons.fastfood_rounded, color: Color(0xFF7C3AED), size: 28)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAi ? Icons.auto_awesome : Icons.qr_code_2,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTypography.chipText.copyWith(
                        color: const Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: AppTypography.heading3.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          mealTime,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.calories.toInt()} กิโลแคลอรี่',
                        style: AppTypography.heading3.copyWith(
                          color: const Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing arrow icon button
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoOrEmptyState(BuildContext context, NutritionProvider provider) {
    // Demo cards representing Figma Screen 1 layout when DB is fresh
    final demoItems = [
      FoodItem(
        id: 'demo_1',
        name: 'ข้าวกะเพราไก่ไข่ดาว',
        calories: 560,
        protein: 26,
        carbohydrates: 65,
        fat: 20,
        scannedAt: DateTime.now(),
        source: 'ai_vision',
      ),
      FoodItem(
        id: 'demo_2',
        name: 'ข้าวโอ๊ตออร์แกนิก เนเชอร์สพ...',
        calories: 190,
        protein: 6,
        carbohydrates: 32,
        fat: 4,
        scannedAt: DateTime.now().subtract(const Duration(hours: 4)),
        source: 'barcode_scan',
      ),
      FoodItem(
        id: 'demo_3',
        name: 'โยเกิร์ตกรีกพร้อมเบอร์รีรวม',
        calories: 180,
        protein: 12,
        carbohydrates: 20,
        fat: 5,
        scannedAt: DateTime.now().subtract(const Duration(days: 1)),
        source: 'barcode_scan',
      ),
      FoodItem(
        id: 'demo_4',
        name: 'ชามสลัดแซลมอนย่าง',
        calories: 520,
        protein: 34,
        carbohydrates: 28,
        fat: 22,
        scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        source: 'ai_vision',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...demoItems.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFoodCard(context, provider, item),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'เมื่อวานนี้, 23 ต.ค.',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'รวม 700 กิโลแคลอรี่',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ...demoItems.skip(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFoodCard(context, provider, item),
              )),
        ],
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'วันนี้, ${date.day} ต.ค.';
    }
    return '${date.day} ต.ค. ${date.year + 543}';
  }
}
