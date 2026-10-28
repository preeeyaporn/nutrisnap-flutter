import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrisnap/core/services/api_service.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/core/utils/result.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('GeminiService Tests', () {
    setUp(() {
      GeminiServiceImpl.setGlobalApiKey(null);
      GeminiServiceImpl.enableOfflineMockForTesting = true;
    });

    tearDown(() {
      GeminiServiceImpl.enableOfflineMockForTesting = false;
    });

    test(
      'Offline / Mock fallback analyzes image and returns Pad Kra Pao matching Figma Screen 6',
      () async {
        final geminiService =
            GeminiServiceImpl(); // No API key -> demo/mock mode
        final bytes = [1, 2, 3, 4];

        final result = await geminiService.analyzeFoodImage(imageBytes: bytes);

        expect(result.isSuccess, isTrue);
        final analysis = result.dataOrNull!;
        expect(analysis.foodName, 'ผัดกะเพราไข่ดาว');
        expect(analysis.calories, 550.0);
        expect(analysis.protein, 28.0);
        expect(analysis.carbohydrates, 48.0);
        expect(analysis.fat, 22.0);
        expect(analysis.confidence, 0.94);
        expect(analysis.healthScore, 'เกรด B');
        expect(analysis.detectedIngredients, contains('ใบกะเพราสด'));
      },
    );

    test(
      'analyzeFoodText returns nutrition estimation for food query',
      () async {
        final geminiService = GeminiServiceImpl();
        final result = await geminiService.analyzeFoodText(
          textPrompt: 'ส้มตำไทย',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.foodName, 'ส้มตำไทย');
        expect(result.dataOrNull?.calories, 380.0);
      },
    );

    test('askNutritionAdvice provides advice for question', () async {
      final geminiService = GeminiServiceImpl();
      final result = await geminiService.askNutritionAdvice(
        question: 'เมนูนี้เหมาะกับคนลดน้ำหนักไหม?',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, contains('โปรตีน'));
    });

    test(
      'Live API call with apiKey sends POST request and parses candidate response',
      () async {
        final mockApi = MockApiService();
        final geminiService = GeminiServiceImpl(
          apiService: mockApi,
          apiKey: 'AIzaSyFakeKeyForTesting123',
        );

        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async {
          return Result.success({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': '''{
                      "foodName": "ข้าวผัดปู",
                      "estimatedPortion": "1 จาน (300g)",
                      "calories": 480.0,
                      "protein": 22.0,
                      "carbohydrates": 52.0,
                      "fat": 18.0,
                      "sugar": 2.0,
                      "fiber": 1.5,
                      "confidence": 0.96,
                      "healthScore": "เกรด A",
                      "detectedIngredients": ["ข้าว", "เนื้อปู", "ไข่ไก่"],
                      "advice": "รสชาติดี โปรตีนสูง"
                    }''',
                    },
                  ],
                },
              },
            ],
          });
        });

        final result = await geminiService.analyzeFoodImage(
          imageBytes: [1, 2, 3],
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.foodName, 'ข้าวผัดปู');
        expect(result.dataOrNull?.calories, 480.0);
        expect(result.dataOrNull?.healthScore, 'เกรด A');
      },
    );

    test(
      'analyzeFoodImage with userNotes correction returns recalculated dish in offline mode',
      () async {
        final geminiService = GeminiServiceImpl(); // Offline / demo mode

        // Test with "ข้าวมันไก่"
        final resultChickenRice = await geminiService.analyzeFoodImage(
          imageBytes: [1, 2, 3],
          userNotes: 'ข้าวมันไก่พิเศษ',
        );

        expect(resultChickenRice.isSuccess, isTrue);
        final chickenData = resultChickenRice.dataOrNull!;
        expect(chickenData.foodName, contains('ข้าวมันไก่'));
        expect(chickenData.userCorrection, isNotNull);
        expect(chickenData.calories, 595.0);
        expect(chickenData.protein, 29.0);
        expect(chickenData.sodium, 820.0);
        expect(
          chickenData.detectedIngredients,
          contains('เนื้อไก่ตอนต้ม (120 กรัม)'),
        );

        // Test with "ผัดไทย"
        final resultPadThai = await geminiService.analyzeFoodImage(
          imageBytes: [1, 2, 3],
          userNotes: 'ผัดไทยกุ้งสด',
        );

        expect(resultPadThai.isSuccess, isTrue);
        final padThaiData = resultPadThai.dataOrNull!;
        expect(padThaiData.foodName, contains('ผัดไทย'));
        expect(padThaiData.calories, 580.0);
        expect(padThaiData.carbohydrates, 68.0);
        expect(padThaiData.sodium, 960.0);
      },
    );
  });
}
