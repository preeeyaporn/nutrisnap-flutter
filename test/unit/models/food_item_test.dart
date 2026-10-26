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
  });
}
