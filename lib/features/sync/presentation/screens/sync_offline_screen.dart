import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

class SyncOfflineScreen extends StatefulWidget {
  final VoidCallback? onGoToHistory;

  const SyncOfflineScreen({
    super.key,
    this.onGoToHistory,
  });

  @override
  State<SyncOfflineScreen> createState() => _SyncOfflineScreenState();
}

class _SyncOfflineScreenState extends State<SyncOfflineScreen> {
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NutritionProvider>().checkRealConnectivity();
      }
    });

    _connectivityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<NutritionProvider>().checkRealConnectivity();
      }
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

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
                  'สถานะการซิงค์',
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
              await provider.checkRealConnectivity(force: true);
              final ok = await provider.syncCloud();
              if (mounted) {
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
          final isOnline = provider.isOnline;
          final unsyncedCount = provider.unsyncedCount;
          final totalCount = provider.recentScans.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Status Banner
                _buildTopStatusBanner(provider, isOnline),

                const SizedBox(height: 16),

                // Main Central Offline Card
                _buildMainOfflineCard(context, provider, isOnline, unsyncedCount),

                const SizedBox(height: 20),

                // Capabilities List
                _buildCapabilitiesSection(),

                const SizedBox(height: 20),

                // Cached Items Strip
                _buildCachedItemsSection(provider, totalCount),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, provider, isOnline),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopStatusBanner(NutritionProvider provider, bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFF86EFAC) : const Color(0xFFDDD6FE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.cloud_off_rounded,
            color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOnline
                  ? 'เชื่อมต่ออินเทอร์เน็ต • ระบบพร้อมซิงค์ Firestore'
                  : 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต • SQLite / Hive พร้อมทำงาน',
              style: AppTypography.bodySmall.copyWith(
                color: isOnline ? const Color(0xFF15803D) : const Color(0xFF6B21A8),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
            ),
            tooltip: 'ตรวจสอบสัญญาณเน็ตจริง',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final status = await provider.checkRealConnectivity(force: true);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(status ? 'ตรวจพบการเชื่อมต่ออินเทอร์เน็ต (Online)' : 'ไม่มีสัญญาณอินเทอร์เน็ต (Offline)'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: isOnline,
              activeThumbColor: const Color(0xFF16A34A),
              activeTrackColor: const Color(0xFFDCFCE7),
              inactiveThumbColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFFDDD6FE),
              onChanged: (val) {
                provider.setOnlineStatus(val, isManual: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOfflineCard(
    BuildContext context,
    NutritionProvider provider,
    bool isOnline,
    int unsyncedCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon graphic
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 42,
                  color: Color(0xFFA78BFA),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dns_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            isOnline ? 'สถานะออนไลน์ปกติ' : 'คุณกำลังออฟไลน์',
            style: AppTypography.heading3.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            isOnline
                ? 'ระบบทำการเชื่อมต่อกับฐานข้อมูล Cloud Firestore เรียบร้อยแล้ว ข้อมูลจะถูกซิงค์ตามเวลาจริง'
                : 'ไม่ต้องกังวล! NutriSnap จะบันทึกข้อมูลมื้ออาหารทั้งหมดของคุณอย่างปลอดภัยใน ฐานข้อมูลภายในเครื่อง (Hive DB) ข้อมูลของคุณจะไม่สูญหาย',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          // Unsynced badge internal card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3E8FF)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_history_rounded, color: Color(0xFF7C3AED), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ระบบจัดเก็บข้อมูล\nมี $unsyncedCount มื้ออาหารที่รอการซิงค์',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4C1D95),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'ความสามารถของอุปกรณ์ขณะออฟไลน์',
                style: AppTypography.heading3.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ระบบสำรองภายในเครื่อง V2',
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCapabilityTile(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF3E8FF),
          title: 'บันทึกมื้ออาหารแบบออฟไลน์',
          subtitle: 'เปิดใช้งานอยู่ (จัดเก็บภายใน Hive DB ในเครื่อง)',
        ),
        const SizedBox(height: 8),
        _buildCapabilityTile(
          icon: Icons.qr_code_scanner_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF3E8FF),
          title: 'แคชข้อมูลบาร์โค้ด',
          subtitle: 'ใช้งานได้สำหรับอาหารทั่วไปและรายการที่เคยบันทึก',
        ),
        const SizedBox(height: 8),
        _buildCapabilityTile(
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF3E8FF),
          title: 'Gemini AI & ซิงค์ข้อมูลคลาวด์',
          subtitle: 'เข้าคิวรอจนกว่าจะเชื่อมต่ออินเทอร์เน็ตได้',
        ),
      ],
    );
  }

  Widget _buildCapabilityTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading3.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedItemsSection(NutritionProvider provider, int totalCount) {
    final recentItems = provider.recentScans.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'รายการที่แคชไว้ในเครื่อง',
                      style: AppTypography.heading3.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalCount มื้อ • 1.8 MB',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              ...recentItems.map((item) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                  )),
              Expanded(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Color(0xFF7C3AED), size: 20),
                      const SizedBox(height: 2),
                      Text(
                        '+ เพิ่มบันทึก',
                        style: AppTypography.chipText.copyWith(
                          color: const Color(0xFF7C3AED),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, NutritionProvider provider, bool isOnline) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final ok = await provider.syncCloud();
              if (mounted) {
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ซิงค์ข้อมูลเมื่อออนไลน์',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF3E8FF),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: widget.onGoToHistory,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF7C3AED), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เข้าสู่ไดอารี่ออฟไลน์ต่อ',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
