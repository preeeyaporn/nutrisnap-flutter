import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';
import 'package:nutrisnap/features/nutrition/presentation/widgets/food_image_view.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;

  const HistoryScreen({
    super.key,
    this.onNavigateTab,
  });

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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final provider = context.read<NutritionProvider>();
              UserModel? authUser;
              try {
                authUser = Provider.of<AuthProvider?>(context, listen: false)?.currentUser;
              } catch (_) {}
              if (authUser != null) {
                final effectiveId = (authUser.email != null && authUser.email!.contains('@'))
                    ? authUser.email!.trim()
                    : authUser.id;
                provider.updateUserInfo(
                  newUserId: effectiveId,
                  email: authUser.email,
                  displayName: authUser.displayName,
                  dailyTarget: authUser.dailyCalorieTarget,
                );
              }
              final ok = await provider.syncCloud();
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'ซิงค์ข้อมูลกับ Firestore สำเร็จ (อัปโหลด ${provider.recentScans.length} รายการ)'
                        : 'ซิงค์ไม่สำเร็จ: ${provider.errorMessage ?? "เกิดข้อผิดพลาด"}'),
                    backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          GestureDetector(
            onTap: () => widget.onNavigateTab?.call(3),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          // สรุปจำนวนมื้อและแคลอรี่รวมของวันนั้น โดยแยกตามที่มา
          final allCount = provider.getMealCountForDate(_selectedDate);
          final barcodeCount = provider.getMealCountForDate(_selectedDate, source: 'barcode_scan');
          final aiCount = provider.getMealCountForDate(_selectedDate, source: 'ai_vision');

          final allCalories = provider.getTotalCaloriesForDate(_selectedDate).toInt();
          final barcodeCalories = provider.getTotalCaloriesForDate(_selectedDate, source: 'barcode_scan').toInt();
          final aiCalories = provider.getTotalCaloriesForDate(_selectedDate, source: 'ai_vision').toInt();

          final items = provider.getFilteredScansForDate(_selectedDate);

          final currentDisplayCount = items.length;

          final totalCalories = provider.selectedFilter == 'barcode_scan'
              ? barcodeCalories
              : (provider.selectedFilter == 'ai_vision' ? aiCalories : allCalories);

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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      const SizedBox(height: 14),

                      // Daily Source Breakdown Cards (Barcode & AI Camera Quick Selector)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                provider.setSelectedFilter(
                                  provider.selectedFilter == 'barcode_scan' ? 'all' : 'barcode_scan',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: provider.selectedFilter == 'barcode_scan'
                                      ? const Color(0xFFF3E8FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: provider.selectedFilter == 'barcode_scan'
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFFE2E8F0),
                                    width: provider.selectedFilter == 'barcode_scan' ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.qr_code_2_rounded, size: 15, color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'บาร์โค้ด',
                                              style: AppTypography.chipText.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E1B4B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$barcodeCount มื้อ',
                                            style: AppTypography.chipText.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${NumberFormat('#,###').format(barcodeCalories)} kcal',
                                      style: AppTypography.heading3.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                provider.setSelectedFilter(
                                  provider.selectedFilter == 'ai_vision' ? 'all' : 'ai_vision',
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: provider.selectedFilter == 'ai_vision'
                                      ? const Color(0xFFF3E8FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: provider.selectedFilter == 'ai_vision'
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFFE2E8F0),
                                    width: provider.selectedFilter == 'ai_vision' ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'กล้อง AI',
                                              style: AppTypography.chipText.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E1B4B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$aiCount มื้อ',
                                            style: AppTypography.chipText.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${NumberFormat('#,###').format(aiCalories)} kcal',
                                      style: AppTypography.heading3.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                                    'บันทึกแล้ว $currentDisplayCount มื้อ',
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
                                  text: '${NumberFormat('#,###').format(totalCalories)} ',
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
                            _buildFilterPill(provider, '🍴 ทั้งหมด ($allCount)', 'all'),
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
                      child: _buildEmptyDateState(context, provider),
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

  String _getMealTime(FoodItem item) {
    final hour = item.scannedAt.hour;
    final timeStr = DateFormat('HH:mm').format(item.scannedAt);
    String mealName;
    if (hour >= 5 && hour < 11) {
      mealName = 'มื้อเช้า';
    } else if (hour >= 11 && hour < 14) {
      mealName = 'มื้อเที่ยง';
    } else if (hour >= 14 && hour < 17) {
      mealName = 'มื้อว่าง';
    } else {
      mealName = 'มื้อเย็น';
    }
    return '$timeStr น. • $mealName';
  }

  Widget _buildFoodCard(BuildContext context, NutritionProvider provider, FoodItem item) {
    final isAi = item.isAi;
    final badgeLabel = isAi ? '• ✨ AI ประมาณการ' : '• ║█║ บาร์โค้ด';
    final mealTime = _getMealTime(item);

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
                ClipOval(
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFFF1F5F9),
                    child: FoodImageView(
                      item: item,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: const Center(
                        child: Icon(Icons.fastfood_rounded, color: Color(0xFF7C3AED), size: 28),
                      ),
                    ),
                  ),
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

  Widget _buildEmptyDateState(BuildContext context, NutritionProvider provider) {
    final filterName = provider.selectedFilter == 'barcode_scan'
        ? 'จากบาร์โค้ด'
        : (provider.selectedFilter == 'ai_vision' ? 'จากกล้อง AI' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_meals_rounded,
                size: 32,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ไม่มีบันทึกมื้ออาหาร$filterNameในวันนี้',
              style: AppTypography.heading3.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'สามารถสแกนบาร์โค้ดหรือถ่ายภาพอาหารด้วย AI เพื่อบันทึกมื้อนี้ได้ทันที',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (provider.selectedFilter != 'all') ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => provider.setSelectedFilter('all'),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('ดูอาหารทั้งหมดของวันนี้'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    final now = DateTime.now();
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
    final monthStr = months[date.month - 1];
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'วันนี้, ${date.day} $monthStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'เมื่อวาน, ${date.day} $monthStr';
    }
    return '${date.day} $monthStr ${date.year + 543}';
  }
}
