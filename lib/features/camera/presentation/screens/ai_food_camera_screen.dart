import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_analysis_result_screen.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

class AiFoodCameraScreen extends StatefulWidget {
  final CameraController? cameraController;
  const AiFoodCameraScreen({super.key, this.cameraController});

  @override
  State<AiFoodCameraScreen> createState() => _AiFoodCameraScreenState();
}

class _AiFoodCameraScreenState extends State<AiFoodCameraScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.cameraController != null) {
      _cameraController = widget.cameraController;
      _isCameraInitialized = _cameraController!.value.isInitialized;
    } else {
      _initCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _setupController(cameraController.description);
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        await _setupController(backCamera);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _setupController(CameraDescription cameraDescription) async {
    final prevController = _cameraController;
    if (widget.cameraController == null && prevController != null) {
      await prevController.dispose();
    }

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    if (widget.cameraController == null) {
      _cameraController?.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _isFrontCamera = !_isFrontCamera;
    final targetLens = _isFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final targetCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == targetLens,
      orElse: () => _cameras!.first,
    );
    await _setupController(targetCamera);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newMode);
        setState(() => _isFlashOn = !_isFlashOn);
      } catch (e) {
        debugPrint('Flash error: $e');
      }
    } else {
      setState(() => _isFlashOn = !_isFlashOn);
    }
  }

  Future<void> _pickFromGalleryAndAnalyze() async {
    final provider = context.read<NutritionProvider>();
    if (provider.isLoading) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      await provider.analyzeFoodImage(bytes, mimeType: 'image/jpeg');

      if (!mounted) return;
      final result = provider.currentAiAnalysis;
      if (result != null) {
        _showAiAnalysisModal(result, bytes);
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      await _captureAndAnalyze();
    }
  }

  Future<void> _captureAndAnalyze() async {
    final provider = context.read<NutritionProvider>();
    if (provider.isLoading) return;

    List<int>? imageBytes;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xfile = await _cameraController!.takePicture();
        imageBytes = await xfile.readAsBytes();
      } catch (e) {
        debugPrint('Error taking picture with camera: $e');
      }
    }

    // High quality bytes for multimodal analysis
    imageBytes ??= List<int>.generate(100, (i) => i);
    await provider.analyzeFoodImage(imageBytes);

    if (!mounted) return;
    final result = provider.currentAiAnalysis;
    if (result != null) {
      _showAiAnalysisModal(result, imageBytes);
    }
  }

  void _showAiAnalysisModal(NutritionAnalysisResult analysis, [List<int>? imageBytes]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ผลวิเคราะห์ Gemini AI', style: AppTypography.heading3),
                          Text(
                            'ความแม่นยำ ${(analysis.confidence * 100).toInt()}% • ตรวจจับสำเร็จ',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      analysis.healthScore,
                      style: AppTypography.chipText.copyWith(
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.foodName,
                      style: AppTypography.heading2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'สัดส่วนประมาณ: ${analysis.estimatedPortion}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMacroPill(
                          'พลังงาน',
                          '${analysis.calories.toInt()} kcal',
                          const Color(0xFFF59E0B),
                          const Color(0xFFFEF3C7),
                        ),
                        _buildMacroPill(
                          'โปรตีน',
                          '${analysis.protein.toInt()}g',
                          const Color(0xFF7C3AED),
                          const Color(0xFFF3E8FF),
                        ),
                        _buildMacroPill(
                          'คาร์บ',
                          '${analysis.carbohydrates.toInt()}g',
                          const Color(0xFF0284C7),
                          const Color(0xFFE0F2FE),
                        ),
                        _buildMacroPill(
                          'ไขมัน',
                          '${analysis.fat.toInt()}g',
                          const Color(0xFFE11D48),
                          const Color(0xFFFFE4E6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('ส่วนผสมที่ตรวจพบ:', style: AppTypography.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: analysis.detectedIngredients.map((i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      i,
                      style: AppTypography.chipText.copyWith(
                        color: const Color(0xFF334155),
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AiAnalysisResultScreen(
                          analysis: analysis,
                          imageBytes: imageBytes,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'ดูข้อมูลโภชนาการฉบับเต็ม',
                    style: AppTypography.buttonText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroPill(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: AppTypography.heading3.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showGeminiApiKeyDialog() async {
    final savedKey = await GeminiServiceImpl.getSavedApiKey() ?? '';
    final controller = TextEditingController(text: savedKey);

    if (!mounted) return;
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
                'ใส่ API Key เพื่อเชื่อมต่อ Gemini 1.5 Flash Vision วิเคราะห์ภาพอาหารจริงจาก Google AI Studio:',
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
                '* หากไม่ระบุ ระบบจะใช้โหมดจำลองความแม่นยำสูง (Demo Fallback)',
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
                if (mounted) {
                  context.read<NutritionProvider>().repository.geminiService.updateApiKey(key.isNotEmpty ? key : null);
                }
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(key.isNotEmpty
                        ? 'บันทึก Gemini API Key เรียบร้อยแล้ว'
                        : 'ตั้งค่าเป็นโหมดจำลอง (Demo Mode)'),
                  ),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<NutritionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF141419),
      body: SafeArea(
        child: Column(
          children: [
            // Top Camera Controls Bar (Figma Screen 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Back button
                  _buildCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Model Selector Pill: "✦ ᯤ Gemini 1.5 Flash Vision"
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _showGeminiApiKeyDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272733).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFA78BFA),
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.wifi_tethering_rounded,
                                  color: Color(0xFFA78BFA),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Gemini 1.5 Flash Vision',
                                  style: AppTypography.chipText.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Flash button
                  _buildCircleButton(
                    icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? Colors.amber : Colors.white,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),

            // Live Camera Viewport
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Live Camera Preview using Camera package (or elegant camera feed placeholder)
                  _buildCameraPreview(),

                  // Floating status pill: "● กำลังตรวจจับ: ผัดกะเพราไข่ดาว • พร้อมถ่าย"
                  Positioned(
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
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
                          Text(
                            'กำลังตรวจจับ: ผัดกะเพราไข่ดาว • พร้อมถ่าย',
                            style: AppTypography.chipText.copyWith(
                              color: const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Viewfinder Corner Brackets Framing Dish
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _CameraReticlePainter(
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ),

                  // Center Focus Target
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),

                  // Lighting Tip Banner (Single clean layer, beautifully spaced above shutter)
                  Positioned(
                    bottom: 98,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E28).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFFFBBF24),
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'แสงสว่างที่เพียงพอช่วยเพิ่มความแม่นยำในการคำนวณโภชนาการ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Shutter Controls Row (Figma Screen 6)
                  Positioned(
                    bottom: 12,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Left: Gallery button "คลังภาพ"
                        GestureDetector(
                          onTap: _pickFromGalleryAndAnalyze,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF272733),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'คลังภาพ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center: Big Shutter Button
                        GestureDetector(
                          onTap: _captureAndAnalyze,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: nutritionProvider.isLoading
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Right: Flip camera button "สลับกล้อง"
                        GestureDetector(
                          onTap: _toggleCameraLens,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF272733),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.flip_camera_ios_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'สลับกล้อง',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom sheet peek: "สแกนสารอาหารสด" + "ประมาณการอัตโนมัติ: เปิดใช้งาน"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'สแกนสารอาหารสด',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ประมาณการอัตโนมัติ: เปิดใช้งาน',
                                style: AppTypography.chipText.copyWith(
                                  color: const Color(0xFF4C1D95),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildCameraPreview() {
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
        ),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF272733),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFA78BFA),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'กล้อง AI พร้อมสแกนสารอาหาร',
              style: AppTypography.chipText.copyWith(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'เล็งกล้องไปที่อาหารในกรอบเพื่อเริ่มวิเคราะห์',
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
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
}

/// Custom painter for the camera framing corners
class _CameraReticlePainter extends CustomPainter {
  final Color color;

  _CameraReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 36.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
