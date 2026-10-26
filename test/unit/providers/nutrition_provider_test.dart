import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

class MockNutriSnapRepository extends Mock implements NutriSnapRepositoryImpl {}

void main() {
  group('NutritionProvider Tests', () {
    late MockNutriSnapRepository mockRepo;
    late NutritionProvider provider;

    final sampleFood = FoodItem(
      id: 'food_1',
      barcode: '8850188800123',
      name: 'น้ำมะพร้าว',
      calories: 65,
      protein: 1.2,
      carbohydrates: 15,
      fat: 0.2,
      scannedAt: DateTime(2026, 9, 24),
    );

    setUp(() {
      mockRepo = MockNutriSnapRepository();
      when(
        () => mockRepo.getRecentScans(limit: any(named: 'limit')),
      ).thenAnswer((_) async => Result.success([sampleFood]));

      provider = NutritionProvider(repository: mockRepo);
    });

    test('Initial state loads recent scans', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.recentScans.length, 1);
      expect(provider.recentScans.first.name, 'น้ำมะพร้าว');
    });

    test('scanBarcode sets currentProduct on success', () async {
      when(
        () => mockRepo.getFoodItemByBarcode('8850188800123'),
      ).thenAnswer((_) async => Result.success(sampleFood));

      final success = await provider.scanBarcode('8850188800123');

      expect(success, isTrue);
      expect(provider.scanStatus, ScanStatus.success);
      expect(provider.currentProduct?.name, 'น้ำมะพร้าว');
    });

    test('scanBarcode handles failure and sets error status', () async {
      when(
        () => mockRepo.getFoodItemByBarcode('999'),
      ).thenAnswer((_) async => const Result.failure('ไม่พบข้อมูล'));

      final success = await provider.scanBarcode('999');

      expect(success, isFalse);
      expect(provider.scanStatus, ScanStatus.error);
      expect(provider.errorMessage, 'ไม่พบข้อมูล');
    });

    test('analyzeFoodImage updates AI analysis and currentProduct', () async {
      final analysis = NutritionAnalysisResult(
        foodName: 'ผัดกะเพรา',
        estimatedPortion: '1 จาน',
        calories: 550,
        protein: 28,
        carbohydrates: 48,
        fat: 22,
        confidence: 0.94,
        healthScore: 'เกรด B',
        analyzedAt: DateTime.now(),
      );

      when(
        () => mockRepo.analyzeFoodImage(
          imageBytes: any(named: 'imageBytes'),
          userNotes: any(named: 'userNotes'),
        ),
      ).thenAnswer((_) async => Result.success(analysis));

      final ok = await provider.analyzeFoodImage([1, 2, 3]);

      expect(ok, isTrue);
      expect(provider.currentAiAnalysis?.foodName, 'ผัดกะเพรา');
      expect(provider.currentProduct?.name, 'ผัดกะเพรา');
    });

    test('clearCurrentProduct resets current item state', () {
      provider.setCurrentProduct(sampleFood);
      expect(provider.currentProduct, isNotNull);

      provider.clearCurrentProduct();
      expect(provider.currentProduct, isNull);
      expect(provider.scanStatus, ScanStatus.idle);
    });
  });
}
