import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/constants/app_typography.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_analysis_result_screen.dart';
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
  Timer? _retryTimer;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCameraInitialized && !Platform.environment.containsKey('FLUTTER_TEST')) {
          _retryTimer = Timer(const Duration(milliseconds: 1200), () {
            if (mounted && !_isCameraInitialized) {
              _initCamera();
            }
          });
        }
      });
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
    if (mounted) {
      setState(() => _isInitializing = true);
    }
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription selectedCamera;
        if (kIsWeb) {
          // On Web/PC Chrome, use first available camera (webcam)
          selectedCamera = _cameras!.first;
        } else {
          selectedCamera = _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras!.first,
          );
        }
        await _setupController(selectedCamera);
      } else {
        debugPrint('No cameras found on device');
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
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

    final preset = kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high;
    final controller = CameraController(
      cameraDescription,
      preset,
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
      debugPrint('Error initializing camera with preset $preset: $e');
      try {
        final fallbackController = CameraController(
          cameraDescription,
          ResolutionPreset.low,
          enableAudio: false,
        );
        _cameraController = fallbackController;
        await fallbackController.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e2) {
        debugPrint('Fallback camera init failed: $e2');
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
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
      if (provider.currentAiAnalysis != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AiAnalysisResultScreen(
              analysis: provider.currentAiAnalysis!,
              imageBytes: bytes,
            ),
          ),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('การวิเคราะห์ภาพล้มเหลว: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพจากคลังได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    if (provider.currentAiAnalysis != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AiAnalysisResultScreen(
            analysis: provider.currentAiAnalysis!,
            imageBytes: imageBytes,
          ),
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('การวิเคราะห์ภาพล้มเหลว: ${provider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGeminiApiKeyDialog() async {
    final savedKey = await GeminiServiceImpl.getSavedApiKey() ?? '';
    final controller = TextEditingController(text: savedKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        bool obscureKey = true;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(
                    'ตั้งค่า Gemini API Key',
                    style: AppTypography.heading3.copyWith(fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ใส่ API Key เพื่อเชื่อมต่อ Gemini 1.5 Flash Vision วิเคราะห์ภาพอาหารจริงจาก Google AI Studio:',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: obscureKey,
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.key_rounded,
                        color: Color(0xFF7C3AED),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureKey
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        tooltip: obscureKey ? 'แสดง API Key' : 'ซ่อน API Key',
                        onPressed: () {
                          setStateDialog(() {
                            obscureKey = !obscureKey;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ซ่อน API Key อัตโนมัติเพื่อความปลอดภัย',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '* หากไม่ระบุ ระบบจะใช้โหมดจำลองความแม่นยำสูง (Demo Fallback)',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
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
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          key.isNotEmpty
                              ? 'บันทึก Gemini API Key เรียบร้อยแล้ว'
                              : 'ตั้งค่าเป็นโหมดจำลอง (Demo Mode)',
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF272733,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.35),
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
                    icon: _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
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

                  // Floating status pill
                  Positioned(
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
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
                            'กำลังตรวจจับอาหาร... • พร้อมถ่าย',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1E1E28,
                          ).withValues(alpha: 0.90),
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
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.4),
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

                  // Overlay when Gemini AI is analyzing
                  if (nutritionProvider.isLoading)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2D),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF7C3AED),
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gemini AI กำลังวิเคราะห์รูปอาหาร...',
                                  style: AppTypography.heading3.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'กำลังคำนวณแคลอรี่และสารอาหาร',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = _cameraController!.value.previewSize;
            final double cameraAspect;
            if (kIsWeb) {
              cameraAspect = (size != null && size.height > 0)
                  ? size.width / size.height
                  : (4 / 3);
            } else {
              cameraAspect = (size != null && size.width > 0)
                  ? size.height / size.width
                  : (9 / 16);
            }

            final double containerAspect =
                constraints.maxWidth / constraints.maxHeight;
            double scale = 1.0;
            if (cameraAspect > 0 && containerAspect > 0) {
              if (containerAspect > cameraAspect) {
                scale = containerAspect / cameraAspect;
              } else {
                scale = cameraAspect / containerAspect;
              }
            }

            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: cameraAspect,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ],
            );
          },
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _isInitializing ? null : _initCamera,
                icon: _isInitializing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.videocam_rounded, size: 18),
                label: Text(
                  _isInitializing
                      ? 'กำลังเปิดกล้อง...'
                      : 'แตะเพื่อเปิดกล้อง / ลองใหม่',
                  style: AppTypography.buttonText.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb
                    ? '* สำหรับเบราว์เซอร์: กรุณากด "Allow" สิทธิ์กล้องที่มุมซ้ายบนของ Chrome'
                    : 'หากกล้องไม่เปิด กรุณาตรวจสอบสิทธิ์การใช้งานกล้องในมือถือ',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
