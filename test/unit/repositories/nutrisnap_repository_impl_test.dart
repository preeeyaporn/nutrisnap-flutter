import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

class MockOpenFoodFactsService extends Mock implements OpenFoodFactsService {}

class MockGeminiService extends Mock implements GeminiService {}

void main() {
  group('NutriSnapRepositoryImpl Tests', () {
    late MockFoodRepository mockLocal;
    late MockFoodRepository mockCloud;
    late MockOpenFoodFactsService mockOff;
    late MockGeminiService mockGemini;
    late NutriSnapRepositoryImpl repository;

    final sampleFood = FoodItem(
      id: 'item_1',
      barcode: '8850188800123',
      name: 'น้ำมะพร้าว',
      calories: 65,
      protein: 1.2,
      carbohydrates: 15,
      fat: 0.2,
      scannedAt: DateTime(2026, 9, 24),
    );

    setUpAll(() {
      registerFallbackValue(sampleFood);
    });

    setUp(() {
      mockLocal = MockFoodRepository();
      mockCloud = MockFoodRepository();
      mockOff = MockOpenFoodFactsService();
      mockGemini = MockGeminiService();

      repository = NutriSnapRepositoryImpl(
        localRepository: mockLocal,
        cloudRepository: mockCloud,
        openFoodFactsService: mockOff,
        geminiService: mockGemini,
      );
    });

    test('saveFoodItem saves to local and triggers cloud sync', () async {
      when(
        () => mockLocal.saveFoodItem(any()),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => mockCloud.saveFoodItem(any()),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.saveFoodItem(sampleFood);
      expect(result.isSuccess, isTrue);
      verify(() => mockLocal.saveFoodItem(sampleFood)).called(1);
    });

    test(
      'getFoodItemByBarcode returns cached item when present locally',
      () async {
        when(
          () => mockLocal.getFoodItemByBarcode('8850188800123'),
        ).thenAnswer((_) async => Result.success(sampleFood));

        final result = await repository.getFoodItemByBarcode('8850188800123');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.name, 'น้ำมะพร้าว');
        verifyNever(() => mockOff.getProductByBarcode(any()));
      },
    );

    test(
      'getFoodItemByBarcode fetches from Open Food Facts when cache misses',
      () async {
        when(
          () => mockLocal.getFoodItemByBarcode('8850188800123'),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockOff.getProductByBarcode('8850188800123'),
        ).thenAnswer((_) async => Result.success(sampleFood));
        when(
          () => mockLocal.saveFoodItem(any()),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockCloud.saveFoodItem(any()),
        ).thenAnswer((_) async => const Result.success(null));

        final result = await repository.getFoodItemByBarcode('8850188800123');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.name, 'น้ำมะพร้าว');
        verify(() => mockOff.getProductByBarcode('8850188800123')).called(1);
      },
    );

    test('analyzeFoodImage calls Gemini service and persists result', () async {
      final analysis = NutritionAnalysisResult(
        foodName: 'ผัดกะเพรา',
        estimatedPortion: '1 จาน',
        calories: 550,
        protein: 28,
        carbohydrates: 48,
        fat: 22,
        confidence: 0.95,
        healthScore: 'เกรด B',
        analyzedAt: DateTime.now(),
      );

      when(
        () => mockGemini.analyzeFoodImage(
          imageBytes: any(named: 'imageBytes'),
          mimeType: any(named: 'mimeType'),
          userNotes: any(named: 'userNotes'),
        ),
      ).thenAnswer((_) async => Result.success(analysis));

      when(
        () => mockLocal.saveFoodItem(any()),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => mockCloud.saveFoodItem(any()),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.analyzeFoodImage(imageBytes: [1, 2, 3]);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.foodName, 'ผัดกะเพรา');
      verify(() => mockLocal.saveFoodItem(any())).called(1);
    });
  });
}
