import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/auth/presentation/screens/login_screen.dart';
import 'package:nutrisnap/features/home/presentation/screens/home_screen.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const _HistoryTab(),
      const _SyncTab(),
      const _ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'หน้าหลัก',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_rounded,
                  label: 'ประวัติ',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.cloud_sync_rounded,
                  label: 'ซิงค์ข้อมูล',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'ตั้งค่า',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.chipText.copyWith(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ประวัติการสแกนและโภชนาการ', style: AppTypography.heading3),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
            onPressed: () async {
              final ok = await context.read<NutritionProvider>().syncCloud();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'ซิงค์ข้อมูลกับ Firestore สำเร็จ' : 'ซิงค์ข้อมูลไม่สำเร็จ'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, child) {
          final items = provider.recentScans;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('ยังไม่มีประวัติการสแกนอาหาร', style: AppTypography.bodyMedium),
                  const SizedBox(height: 6),
                  Text('สแกนบาร์โค้ดหรือถ่ายภาพอาหารเพื่อเริ่มต้น', style: AppTypography.bodySmall),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.source == 'barcode_scan'
                          ? Icons.qr_code_2_rounded
                          : Icons.auto_awesome,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: AppTypography.heading3.copyWith(fontSize: 15),
                  ),
                  subtitle: Text(
                    '${item.calories.toInt()} kcal • โปรตีน ${item.protein.toInt()}g • เกรด ${item.nutriScore ?? "A"}',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NutritionDetailScreen(item: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SyncTab extends StatelessWidget {
  const _SyncTab();

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<NutritionProvider>();
    final itemsCount = nutritionProvider.recentScans.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ซิงค์ข้อมูลคลาวด์', style: AppTypography.heading3),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Cloud Firestore Synchronization',
                    style: AppTypography.heading2.copyWith(fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สำรองข้อมูลการสแกนและโภชนาการของคุณขึ้นคลาวด์อย่างปลอดภัย เข้าถึงได้จากทุกอุปกรณ์',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ข้อมูลท้องถิ่นใน Hive', style: AppTypography.bodyMedium),
                        Text('$itemsCount รายการ', style: AppTypography.heading3.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () async {
                        final ok = await context.read<NutritionProvider>().syncCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'ซิงค์ข้อมูลกับ Firestore สำเร็จ' : 'ซิงค์ข้อมูลไม่สำเร็จ'),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.sync_rounded, color: Colors.white),
                      label: Text(
                        'ซิงค์ข้อมูลเดี๋ยวนี้',
                        style: AppTypography.buttonText,
                      ),
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (user?.isAnonymous == true ? 'ผู้ใช้งานทั่วไป (Guest)' : 'ผู้ใช้งาน NutriSnap');
    final emailText = user?.email ?? (user?.isAnonymous == true ? 'โหมดทดลองใช้งาน' : 'ยังไม่ได้ระบุอีเมล');
    final targetKcal = user?.dailyCalorieTarget.toStringAsFixed(0) ?? '2,000';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('โปรไฟล์และตั้งค่า', style: AppTypography.heading3),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: AppTypography.heading3),
                        const SizedBox(height: 2),
                        Text(emailText, style: AppTypography.bodySmall.copyWith(color: AppColors.neutralSecondary)),
                        const SizedBox(height: 2),
                        Text('เป้าหมาย $targetKcal kcal / วัน', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: user?.isAnonymous == true ? const Color(0xFFF1F5F9) : AppColors.primaryLavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.isAnonymous == true ? 'GUEST' : 'PRO',
                      style: AppTypography.chipText.copyWith(
                        color: user?.isAnonymous == true ? const Color(0xFF64748B) : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings list
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                    title: Text('ซิงค์ข้อมูลกับ Firestore', style: AppTypography.bodyMedium),
                    subtitle: Text('เชื่อมต่อ Firebase และสำรองข้อมูล', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final ok = await context.read<NutritionProvider>().syncCloud();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'ซิงค์ข้อมูลแล้ว' : 'ไม่สามารถซิงค์ได้')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.psychology_outlined, color: AppColors.primary),
                    title: Text('Gemini API Integration', style: AppTypography.bodyMedium),
                    subtitle: Text('โมเดล: Gemini 1.5 Flash Vision', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined, color: AppColors.primary),
                    title: Text('ฐานข้อมูลท้องถิ่น (Local DB)', style: AppTypography.bodyMedium),
                    subtitle: Text('ขับเคลื่อนโดย Hive NoSQL Database', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: Text('ออกจากระบบ', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                    subtitle: Text('ออกจากบัญชีและกลับไปที่หน้าเข้าสู่ระบบ', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ออกจากระบบ'),
                          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
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
