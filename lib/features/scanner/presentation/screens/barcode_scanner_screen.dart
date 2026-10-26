import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_colors.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final MobileScannerController? controller;
  const BarcodeScannerScreen({super.key, this.controller});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  late final MobileScannerController _scannerController;
  late final bool _isCustomController;

  bool _isFlashOn = false;
  bool _showTip = true;
  String _currentBarcode = '8850188800123';

  @override
  void initState() {
    super.initState();
    _isCustomController = widget.controller != null;
    _scannerController =
        widget.controller ??
        MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Trigger initial scan for demo product
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().scanBarcode(_currentBarcode);
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    if (!_isCustomController) {
      _scannerController.dispose();
    }
    super.dispose();
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    try {
      _scannerController.toggleTorch();
    } catch (_) {}
  }

  void _onDetectBarcode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty && code != _currentBarcode) {
        setState(() => _currentBarcode = code);
        context.read<NutritionProvider>().scanBarcode(code);
        break;
      }
    }
  }

  void _showManualBarcodeDialog() {
    final controller = TextEditingController(text: _currentBarcode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('พิมพ์รหัสบาร์โค้ด', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ป้อนรหัสบาร์โค้ด EAN-13 หรือ UPC เพื่อดึงข้อมูลโภชนาการจาก Open Food Facts',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'เช่น 8850188800123',
                prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ยกเลิก', style: AppTypography.chipText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final code = controller.text.trim();
              Navigator.of(ctx).pop();
              if (code.isNotEmpty) {
                setState(() => _currentBarcode = code);
                final success = await context.read<NutritionProvider>().scanBarcode(code);
                if (!mounted) return;
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ไม่พบข้อมูลสินค้ารหัส $code ในระบบ Open Food Facts'),
                      backgroundColor: AppColors.warning,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              'ค้นหา',
              style: AppTypography.buttonText.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('คำแนะนำการสแกน', style: AppTypography.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• จัดบาร์โค้ดให้อยู่ในกรอบแสงสีม่วง',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '• ถือกล้องนิ่งห่างประมาณ 10-15 ซม.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '• หากแสงไม่พอ ให้เปิดไฟฉายที่มุมขวาบน',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '• สามารถอัปโหลดรูปภาพบาร์โค้ดจากคลังภาพได้',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'เข้าใจแล้ว',
              style: AppTypography.buttonText.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<NutritionProvider>();
    final scannedItem = nutritionProvider.currentProduct;

    return Scaffold(
      backgroundColor: const Color(0xFF141419),
      body: SafeArea(
        child: Column(
          children: [
            // Top Camera Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  _buildCircularButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // "● ระบบตรวจจับบาร์โค้ดสด"
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ระบบตรวจจับบาร์โค้ดสด',
                                style: AppTypography.chipText.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flashlight toggle
                  _buildCircularButton(
                    icon: _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: _isFlashOn ? Colors.amber : Colors.white,
                    onTap: _toggleFlash,
                  ),
                  const SizedBox(width: 8),
                  // Help button
                  _buildCircularButton(
                    icon: Icons.help_outline_rounded,
                    onTap: _showHelpDialog,
                  ),
                ],
              ),
            ),

            // Scanner Viewport & Reticle Area
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Live Camera feed with mobile_scanner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E26),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetectBarcode,
                      errorBuilder: (context, error) {
                        return Container(
                          color: const Color(0xFF1E1E26),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ระบบตรวจจับบาร์โค้ดพร้อมทำงาน',
                                  style: AppTypography.chipText.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Scanner Reticle with glowing laser line
                  SizedBox(
                    width: 250,
                    height: 160,
                    child: Stack(
                      children: [
                        // Reticle Corners
                        CustomPaint(
                          size: const Size(250, 160),
                          painter: _ScannerFramePainter(
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),

                        // Barcode graphic stripes watermark
                        Center(
                          child: Icon(
                            Icons.view_column_rounded,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),

                        // Animated scanning laser line
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 160 * _laserAnimation.value,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA78BFA),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.9),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // "จัดบาร์โค้ดให้อยู่ในกรอบ" Pill positioned at TOP (Clean UX, never overlapping)
                  Positioned(
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.crop_free_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'จัดบาร์โค้ดให้อยู่ในกรอบ',
                            style: AppTypography.chipText.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls & Search Status in a single structured Column (ZERO overlap!)
                  Positioned(
                    bottom: 10,
                    left: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live Search Status Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF272733,
                            ).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4C1D95),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFA78BFA),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'การค้นหาสด',
                                      style: AppTypography.chipText.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'กำลังค้นหาในฐานข้อมูล Open Food Facts...',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 10.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.sync_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                onPressed: () {
                                  context.read<NutritionProvider>().scanBarcode(
                                    _currentBarcode,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Action Buttons: "📷 อัปโหลดรูปภาพ" & "⌨️ พิมพ์รหัสบาร์โค้ด"
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionPill(
                                icon: Icons.image_outlined,
                                label: 'อัปโหลดรูปภาพ',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'กำลังสแกนรูปภาพจากคลังรูป...',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  context.read<NutritionProvider>().scanBarcode(
                                    _currentBarcode,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionPill(
                                icon: Icons.keyboard_alt_outlined,
                                label: 'พิมพ์รหัสบาร์โค้ด',
                                onTap: _showManualBarcodeDialog,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Scanned Result Card / Bottom Sheet (Figma Screen 4)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          Text(
                            'สแกนสำเร็จแล้ว',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'EAN-13',
                          style: AppTypography.chipText.copyWith(
                            color: const Color(0xFF475569),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Barcode Box Card (Figma Screen 4)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDDD6FE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF7C3AED),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentBarcode,
                                style: AppTypography.barcodeDisplay.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E1B4B),
                                ),
                              ),
                              Text(
                                'พร้อมดึงข้อมูลโภชนาการ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF7C3AED),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Preview Row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_drink_rounded,
                          color: Color(0xFF0284C7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nutritionProvider.scanStatus == ScanStatus.scanning
                                  ? 'กำลังค้นหาข้อมูลสินค้า...'
                                  : (scannedItem?.name ??
                                      (nutritionProvider.scanStatus == ScanStatus.error
                                          ? 'ไม่พบข้อมูลสินค้ารหัสนี้'
                                          : 'น้ำมะพร้าวสดออร์แกนิก 100%')),
                              style: AppTypography.heading3.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              nutritionProvider.scanStatus == ScanStatus.scanning
                                  ? 'กำลังเชื่อมต่อ Open Food Facts...'
                                  : (scannedItem != null
                                      ? '${scannedItem.brand.isNotEmpty ? "${scannedItem.brand} • " : ""}${scannedItem.servingSize}'
                                      : (nutritionProvider.scanStatus == ScanStatus.error
                                          ? 'ไม่มีในฐานข้อมูล Open Food Facts'
                                          : '330 มล. • สด 100%')),
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'เกรด ${scannedItem?.nutriScore ?? "A"}',
                          style: AppTypography.chipText.copyWith(
                            color: const Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Main Button: "ดูข้อมูลโภชนาการฉบับเต็ม"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (nutritionProvider.scanStatus == ScanStatus.scanning) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กำลังค้นหาข้อมูลสินค้า กรุณารอสักครู่...')),
                            );
                            return;
                          }

                          final item = scannedItem ??
                              FoodItem(
                                id: 'item_sample',
                                barcode: _currentBarcode,
                                name: _currentBarcode == '8850188800123'
                                    ? 'น้ำมะพร้าวสดออร์แกนิก 100%'
                                    : 'สินค้าบาร์โค้ด $_currentBarcode',
                                brand: _currentBarcode == '8850188800123'
                                    ? 'Nature Choice'
                                    : 'ไม่พบใน Open Food Facts',
                                servingSize: _currentBarcode == '8850188800123' ? '330 มล.' : '100g',
                                calories: _currentBarcode == '8850188800123' ? 65 : 0,
                                protein: _currentBarcode == '8850188800123' ? 1.2 : 0,
                                carbohydrates: _currentBarcode == '8850188800123' ? 15 : 0,
                                fat: _currentBarcode == '8850188800123' ? 0.2 : 0,
                                sugar: _currentBarcode == '8850188800123' ? 12 : 0,
                                nutriScore: _currentBarcode == '8850188800123' ? 'A' : null,
                                scannedAt: DateTime.now(),
                              );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  NutritionDetailScreen(item: item),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ดูข้อมูลโภชนาการฉบับเต็ม',
                                style: AppTypography.buttonText.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Tip Banner
                  if (_showTip) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'คำแนะนำ: ถือกล้องนิ่งห่างประมาณ 10–15 ซม. เพื่อการอ่านที่รวดเร็ว',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF4C1D95),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showTip = false),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF33333E).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.chipText.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for glowing corner brackets of barcode scanner
class _ScannerFramePainter extends CustomPainter {
  final Color color;

  _ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 28.0;

    // Top-left
    canvas.drawLine(const Offset(0, corner), const Offset(0, 8), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, 16, 16),
      3.14159,
      1.57079,
      false,
      paint,
    );
    canvas.drawLine(const Offset(8, 0), const Offset(corner, 0), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - corner, 0),
      Offset(size.width - 8, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 16, 0, 16, 16),
      4.71238,
      1.57079,
      false,
      paint,
    );
    canvas.drawLine(Offset(size.width, 8), Offset(size.width, corner), paint);

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - corner),
      Offset(0, size.height - 8),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - 16, 16, 16),
      1.57079,
      1.57079,
      false,
      paint,
    );
    canvas.drawLine(Offset(8, size.height), Offset(corner, size.height), paint);

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - corner, size.height),
      Offset(size.width - 8, size.height),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 16, size.height - 16, 16, 16),
      0,
      1.57079,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - 8),
      Offset(size.width, size.height - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
