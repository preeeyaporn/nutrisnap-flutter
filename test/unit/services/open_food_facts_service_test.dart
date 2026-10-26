import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrisnap/core/services/api_service.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/core/utils/result.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('OpenFoodFactsService Tests', () {
    late MockApiService mockApi;
    late OpenFoodFactsServiceImpl offService;

    setUp(() {
      mockApi = MockApiService();
      offService = OpenFoodFactsServiceImpl(apiService: mockApi);
    });

    test(
      'Special demo barcode (8850188800123 from Figma Screen 4) returns verified coconut water data',
      () async {
        final result = await offService.getProductByBarcode('8850188800123');

        expect(result.isSuccess, isTrue);
        final item = result.dataOrNull!;
        expect(item.name, 'น้ำมะพร้าวสดออร์แกนิก 100%');
        expect(item.calories, 65.0);
        expect(item.protein, 1.2);
        expect(item.nutriScore, 'A');
        expect(item.servingSize, '330 มล.');
      },
    );

    test(
      'getProductByBarcode parses Open Food Facts response correctly',
      () async {
        when(() => mockApi.get(any())).thenAnswer((_) async {
          return Result.success({
            'status': 1,
            'product': {
              'product_name': 'Organic Rolled Oats',
              'product_name_th': 'ข้าวโอ๊ตออร์แกนิก',
              'brands': 'Bob Red Mill',
              'serving_size': '40g',
              'nutrition_grades': 'a',
              'nutriments': {
                'energy-kcal_100g': 380,
                'proteins_100g': 13.0,
                'carbohydrates_100g': 68.0,
                'fat_100g': 6.5,
                'sugars_100g': 1.0,
                'fiber_100g': 10.0,
              },
              'ingredients_text': 'Whole grain rolled oats',
            },
          });
        });

        final result = await offService.getProductByBarcode('1234567890123');

        expect(result.isSuccess, isTrue);
        final item = result.dataOrNull!;
        expect(item.name, 'ข้าวโอ๊ตออร์แกนิก');
        expect(item.calories, 380.0);
        expect(item.protein, 13.0);
        expect(item.nutriScore, 'A');
      },
    );

    test(
      'getProductByBarcode returns failure when product not found',
      () async {
        when(() => mockApi.get(any())).thenAnswer((_) async {
          return Result.success({
            'status': 0,
            'status_verbose': 'product not found',
          });
        });

        final result = await offService.getProductByBarcode('0000000000000');
        expect(result.isFailure, isTrue);
      },
    );

    test('searchProducts returns list of parsed items', () async {
      when(() => mockApi.get(any())).thenAnswer((_) async {
        return Result.success({
          'count': 1,
          'products': [
            {
              'code': '99999',
              'product_name': 'Soy Milk',
              'nutriments': {
                'energy-kcal_100g': 54,
                'proteins_100g': 3.3,
                'carbohydrates_100g': 6.0,
                'fat_100g': 1.8,
              },
            },
          ],
        });
      });

      final result = await offService.searchProducts('soy');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.name, 'Soy Milk');
    });
  });
}
