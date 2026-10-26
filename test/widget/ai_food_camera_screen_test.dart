import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_food_camera_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

class FakeGeminiService implements GeminiService {
  final NutritionAnalysisResult? customAnalysis;

  FakeGeminiService({this.customAnalysis});

  @override
  Future<Result<NutritionAnalysisResult>> analyzeFoodImage({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    String? userNotes,
  }) async {
    return Result.success(
      customAnalysis ??
          NutritionAnalysisResult(
            foodName: 'ผัดกะเพราไข่ดาว',
            estimatedPortion: '1 จาน (320 กรัม)',
            calories: 550.0,
            protein: 28.0,
            carbohydrates: 48.0,
            fat: 22.0,
            sugar: 3.5,
            fiber: 2.1,
            sodium: 780.0,
            confidence: 0.94,
            healthScore: 'เกรด B',
            detectedIngredients: ['ข้าวสวย', 'หมูสับ', 'กะเพรา', 'ไข่ดาว'],
            advice: 'มีโปรตีนสูง',
            analyzedAt: DateTime.now(),
          ),
    );
  }

  @override
  Future<Result<NutritionAnalysisResult>> analyzeFoodText({required String textPrompt}) async {
    return Result.success(
      NutritionAnalysisResult(
        foodName: textPrompt,
        estimatedPortion: '1 จาน',
        calories: 500.0,
        protein: 25.0,
        carbohydrates: 45.0,
        fat: 20.0,
        sugar: 3.0,
        fiber: 2.0,
        sodium: 700.0,
        confidence: 0.90,
        healthScore: 'เกรด B',
        detectedIngredients: [textPrompt],
        advice: 'คำนวณจากข้อความสำเร็จ',
        analyzedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<String>> askNutritionAdvice({required String question, FoodItem? currentFood}) async {
    return Result.success('คำแนะนำทางโภชนาการ');
  }

  @override
  void updateApiKey(String? newKey) {}
}

class FakeLocalRepository implements FoodRepository {
  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async => Result.success(null);

  @override
  Future<Result<FoodItem?>> getFoodItemById(String id) async => Result.success(null);

  @override
  Future<Result<FoodItem?>> getFoodItemByBarcode(String barcode) async => Result.success(null);

  @override
  Future<Result<List<FoodItem>>> getAllFoodItems() async => Result.success([]);

  @override
  Future<Result<List<FoodItem>>> getRecentScans({int limit = 20}) async => Result.success([]);

  @override
  Future<Result<void>> deleteFoodItem(String id) async => Result.success(null);

  @override
  Future<Result<void>> toggleFavorite(String id) async => Result.success(null);

  @override
  Future<Result<void>> clearAll() async => Result.success(null);
}

void main() {
  Widget createTestWidget() {
    final fakeRepo = NutriSnapRepositoryImpl(
      localRepository: FakeLocalRepository(),
      geminiService: FakeGeminiService(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: FirebaseAuthServiceImpl())),
        ChangeNotifierProvider(create: (_) => NutritionProvider(repository: fakeRepo)),
      ],
      child: const MaterialApp(
        home: AiFoodCameraScreen(),
      ),
    );
  }

  group('AiFoodCameraScreen Widget Tests', () {
    testWidgets('renders Figma Screen 6 camera interface', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Top model selector pill
      expect(find.text('Gemini 1.5 Flash Vision'), findsOneWidget);

      // Detection status pill
      expect(find.text('กำลังตรวจจับอาหาร... • พร้อมถ่าย'), findsOneWidget);

      // Lighting hint
      expect(find.text('แสงสว่างที่เพียงพอช่วยเพิ่มความแม่นยำในการคำนวณโภชนาการ'), findsOneWidget);

      // Camera controls
      expect(find.text('คลังภาพ'), findsOneWidget);
      expect(find.text('สลับกล้อง'), findsOneWidget);

      // Bottom sheet peek
      expect(find.text('สแกนสารอาหารสด'), findsOneWidget);
      expect(find.text('ประมาณการอัตโนมัติ: เปิดใช้งาน'), findsOneWidget);
    });

    testWidgets('tapping shutter button triggers analysis bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find the circular shutter button (by camera icon)
      final shutterIcon = find.byIcon(Icons.camera_alt_rounded);
      expect(shutterIcon, findsOneWidget);

      await tester.tap(shutterIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Analysis bottom sheet should appear
      expect(find.text('ผลวิเคราะห์ Gemini AI'), findsOneWidget);
      expect(find.text('ผัดกะเพราไข่ดาว'), findsOneWidget);
      expect(find.text('550 kcal'), findsOneWidget);
      expect(find.text('28g'), findsOneWidget); // protein
    });
  });
}
