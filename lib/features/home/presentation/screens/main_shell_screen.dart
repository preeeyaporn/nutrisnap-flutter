import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';
import 'package:nutrisnap/features/auth/presentation/screens/login_screen.dart';
import 'package:nutrisnap/features/history/presentation/screens/history_screen.dart';
import 'package:nutrisnap/features/home/presentation/screens/home_screen.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/sync/presentation/screens/sync_offline_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      HomeScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const HistoryScreen(),
      SyncOfflineScreen(
        onGoToHistory: () => setState(() => _currentIndex = 1),
      ),
      const _ProfileTab(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NutritionProvider>().checkRealConnectivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    if (authUser != null) {
      final effectiveId = (authUser.email != null && authUser.email!.contains('@'))
          ? authUser.email!.trim()
          : authUser.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NutritionProvider>().updateUserInfo(
            newUserId: effectiveId,
            email: authUser.email,
            displayName: authUser.displayName,
            dailyTarget: authUser.dailyCalorieTarget,
          );
        }
      });
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  icon: Icons.sync_rounded,
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
                        final name = authUser?.displayName.isNotEmpty == true ? authUser!.displayName : (authUser?.email ?? 'ผู้ใช้');
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'ซิงค์ข้อมูลกับ Firestore สำเร็จ (ผู้ใช้: $name)'
                                : 'ไม่สามารถซิงค์ได้: ${provider.errorMessage ?? "เกิดข้อผิดพลาด"}'),
                            backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
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
