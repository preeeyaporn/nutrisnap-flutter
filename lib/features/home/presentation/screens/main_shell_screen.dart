import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_food_camera_screen.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/meal_detail_screen.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';
import 'package:nutrisnap/features/scanner/presentation/screens/barcode_scanner_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AiFoodCameraScreen(),
    BarcodeScannerScreen(),
    _HistoryTab(),
    _ProfileTab(),
  ];

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
                  icon: Icons.camera_alt_rounded,
                  label: 'กล้อง AI',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'สแกนเนอร์',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.history_rounded,
                  label: 'ประวัติ',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'โปรไฟล์',
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
                    if (item.source == 'gemini_vision') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MealDetailScreen(item: item),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NutritionDetailScreen(item: item),
                        ),
                      );
                    }
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
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
                        Text('ผู้ใช้งาน NutriSnap', style: AppTypography.heading3),
                        const SizedBox(height: 2),
                        Text('เป้าหมาย 2,000 kcal / วัน', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('PRO', style: AppTypography.chipText.copyWith(color: AppColors.primary)),
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
                    subtitle: Text('โมเดล: Gemini 1.5 Flash Vision (แตะเพื่อตั้งค่า Key)', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    onTap: () async {
                      final savedKey = await GeminiServiceImpl.getSavedApiKey() ?? '';
                      final controller = TextEditingController(text: savedKey);

                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 8),
                                Text('ตั้งค่า Gemini API Key', style: AppTypography.heading3.copyWith(fontSize: 16)),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ใส่ API Key เพื่อเชื่อมต่อ Gemini 1.5 Flash Vision จาก Google AI Studio:',
                                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF475569)),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: 'AIzaSy...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '* หากเว้นว่าง ระบบจะใช้โหมดจำลอง (Demo Mode) อัตโนมัติ',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: const Color(0xFF94A3B8)),
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
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final key = controller.text.trim();
                                  await GeminiServiceImpl.saveApiKey(key);
                                  if (!context.mounted) return;
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(key.isNotEmpty
                                          ? 'บันทึก Gemini API Key สำเร็จ'
                                          : 'ใช้งานโหมดจำลอง (Demo Mode)'),
                                    ),
                                  );
                                },
                                child: const Text('บันทึก'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined, color: AppColors.primary),
                    title: Text('ฐานข้อมูลท้องถิ่น (Local DB)', style: AppTypography.bodyMedium),
                    subtitle: Text('ขับเคลื่อนโดย Hive NoSQL Database', style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
