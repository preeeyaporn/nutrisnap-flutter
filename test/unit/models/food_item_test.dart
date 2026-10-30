import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';

void main() {
  group('FoodItem Model Tests', () {
    final now = DateTime(2026, 9, 24, 12, 0, 0);

    final sampleFood = FoodItem(
      id: 'test_123',
      barcode: '8850188800123',
      name: 'น้ำมะพร้าวสดออร์แกนิก 100%',
      brand: 'Nature Choice',
      imageUrl: 'assets/images/screen_barcode.png',
      servingSize: '330 มล.',
      calories: 65.0,
      protein: 1.2,
      carbohydrates: 15.0,
      fat: 0.2,
      sugar: 12.0,
      fiber: 1.5,
      nutriScore: 'A',
      scannedAt: now,
      ingredients: const ['น้ำมะพร้าว 100%'],
      source: 'barcode_scan',
      isFavorite: false,
    );

    test('toMap and fromMap should serialize and deserialize correctly', () {
      final map = sampleFood.toMap();
      expect(map['id'], 'test_123');
      expect(map['barcode'], '8850188800123');
      expect(map['calories'], 65.0);
      expect(map['protein'], 1.2);
      expect(map['nutriScore'], 'A');

      final deserialized = FoodItem.fromMap(map);
      expect(deserialized.id, sampleFood.id);
      expect(deserialized.barcode, sampleFood.barcode);
      expect(deserialized.name, sampleFood.name);
      expect(deserialized.calories, sampleFood.calories);
      expect(deserialized.nutriScore, sampleFood.nutriScore);
      expect(deserialized.ingredients, contains('น้ำมะพร้าว 100%'));
    });

    test('toJson and fromJson should work with JSON strings', () {
      final jsonStr = sampleFood.toJson();
      final fromJson = FoodItem.fromJson(jsonStr);

      expect(fromJson.id, sampleFood.id);
      expect(fromJson.name, sampleFood.name);
      expect(fromJson.calories, sampleFood.calories);
    });

    test('copyWith should update specified fields only', () {
      final updated = sampleFood.copyWith(calories: 80.0, isFavorite: true);

      expect(updated.id, sampleFood.id);
      expect(updated.name, sampleFood.name);
      expect(updated.calories, 80.0);
      expect(updated.isFavorite, isTrue);
      expect(sampleFood.isFavorite, isFalse);
    });

    test(
      'FoodItem handles empty or null map gracefully with default values',
      () {
        final item = FoodItem.fromMap(const {});
        expect(item.id, '');
        expect(item.name, 'ไม่ระบุชื่ออาหาร');
        expect(item.calories, 0.0);
        expect(item.protein, 0.0);
        expect(item.servingSize, '100g');
      },
    );

    test('equality and hashCode should work based on id', () {
      final item1 = FoodItem(
        id: 'same_id',
        name: 'Item 1',
        calories: 100,
        protein: 10,
        carbohydrates: 20,
        fat: 5,
        scannedAt: now,
      );
      final item2 = FoodItem(
        id: 'same_id',
        name: 'Item 2',
        calories: 200,
        protein: 20,
        carbohydrates: 40,
        fat: 10,
        scannedAt: now,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('calorie and Thai RDI percentage calculations are mathematically accurate', () {
      // 65 kcal / 2000 kcal * 100 = 3.25%
      expect(sampleFood.caloriePercentage(2000.0), closeTo(3.25, 0.01));

      // Protein: 1.2g / 50g * 100 = 2.4%
      expect(sampleFood.proteinRdiPercentage(50.0), closeTo(2.4, 0.01));

      // Carbs: 15.0g / 300g * 100 = 5.0%
      expect(sampleFood.carbsRdiPercentage(300.0), closeTo(5.0, 0.01));

      // Fat: 0.2g / 65g * 100 = 0.3076% ≈ 0.31%
      expect(sampleFood.fatRdiPercentage(65.0), closeTo(0.307, 0.01));

      // Sugar: 12.0g / 24g * 100 = 50.0%
      expect(sampleFood.sugarRdiPercentage(24.0), closeTo(50.0, 0.01));

      // Atwater factors: Protein 4 kcal/g, Carbs 4 kcal/g, Fat 9 kcal/g
      expect(sampleFood.proteinKcal, closeTo(4.8, 0.01));
      expect(sampleFood.carbsKcal, closeTo(60.0, 0.01));
      expect(sampleFood.fatKcal, closeTo(1.8, 0.01));
      expect(sampleFood.totalMacroKcal, closeTo(66.6, 0.01));

      // Energy distribution ratio sum to 1.0
      final sumRatios = sampleFood.proteinRatio + sampleFood.carbsRatio + sampleFood.fatRatio;
      expect(sumRatios, closeTo(1.0, 0.001));
    });

    test('isAi and isBarcode accurately identify food item source including gemini_vision', () {
      final aiFood = FoodItem(
        id: 'ai_123',
        name: 'ปีกไก่ทอด',
        calories: 650,
        protein: 30,
        carbohydrates: 10,
        fat: 40,
        source: 'gemini_vision',
        scannedAt: now,
      );
      expect(aiFood.isAi, isTrue);
      expect(aiFood.isBarcode, isFalse);
      expect(aiFood.effectiveImageUrl, contains('unsplash.com'));

      final barcodeFood = FoodItem(
        id: 'off_8850123',
        barcode: '8850123',
        name: 'มันฝรั่งทอดกรอบ',
        calories: 220,
        protein: 3,
        carbohydrates: 25,
        fat: 12,
        source: 'barcode_scan',
        scannedAt: now,
      );
      expect(barcodeFood.isAi, isFalse);
      expect(barcodeFood.isBarcode, isTrue);
      expect(barcodeFood.effectiveImageUrl, contains('unsplash.com'));
    });

    test('effectiveImageUrl semantic matching maps water and cassava chips to accurate photos', () {
      final waterItem = FoodItem(
        id: 'water_1',
        name: 'น้ำเปล่า',
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        source: 'ai_vision',
        scannedAt: now,
      );
      // Plain water must NOT show coffee, must show fresh drinking water
      expect(waterItem.effectiveImageUrl, contains('photo-1548839140-29a749e1bc4e'));

      final cassavaChips = FoodItem(
        id: 'snack_1',
        name: 'มันสำปะหลังแผ่นทอดกรอบ รสเกลือ',
        calories: 270,
        protein: 1,
        carbohydrates: 35,
        fat: 14,
        source: 'ai_vision',
        scannedAt: now,
      );
      // Cassava chips must NOT show salad, must show crispy snack/chips
      expect(cassavaChips.effectiveImageUrl, contains('photo-1566478989037-eec170784d0b'));

      final realPhotoItem = FoodItem(
        id: 'real_photo_1',
        name: 'ปีกไก่ทอด',
        calories: 650,
        protein: 30,
        carbohydrates: 10,
        fat: 40,
        imageUrl: '/data/user/0/com.example.nutrisnap/cache/CAP_real_photo.jpg',
        source: 'ai_vision',
        scannedAt: now,
      );
      expect(realPhotoItem.effectiveImageUrl, equals('/data/user/0/com.example.nutrisnap/cache/CAP_real_photo.jpg'));
    });
  });
}
