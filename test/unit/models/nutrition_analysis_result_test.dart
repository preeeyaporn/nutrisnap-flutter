import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';

void main() {
  group('NutritionAnalysisResult Model Tests', () {
    final now = DateTime(2026, 9, 24, 12, 0, 0);

    final sampleResult = NutritionAnalysisResult(
      foodName: 'ผัดกะเพราไข่ดาว',
      estimatedPortion: '1 จาน (320 กรัม)',
      calories: 550.0,
      protein: 28.0,
      carbohydrates: 48.0,
      fat: 22.0,
      sugar: 3.5,
      fiber: 2.1,
      confidence: 0.94,
      healthScore: 'เกรด B',
      detectedIngredients: const ['ข้าวสวย', 'หมูสับ', 'ใบกะเพรา', 'ไข่ดาว'],
      advice: 'ควรลดการใช้น้ำมันในการทอด',
      analyzedAt: now,
    );

    test('toMap and fromMap should serialize correctly', () {
      final map = sampleResult.toMap();
      expect(map['foodName'], 'ผัดกะเพราไข่ดาว');
      expect(map['calories'], 550.0);
      expect(map['confidence'], 0.94);
      expect(map['healthScore'], 'เกรด B');

      final deserialized = NutritionAnalysisResult.fromMap(map);
      expect(deserialized.foodName, sampleResult.foodName);
      expect(deserialized.calories, sampleResult.calories);
      expect(deserialized.protein, sampleResult.protein);
      expect(deserialized.confidence, sampleResult.confidence);
      expect(deserialized.detectedIngredients, contains('หมูสับ'));
    });

    test('toFoodItem should convert analysis into FoodItem entity', () {
      final foodItem = sampleResult.toFoodItem(customId: 'custom_123');
      expect(foodItem.id, 'custom_123');
      expect(foodItem.name, sampleResult.foodName);
      expect(foodItem.calories, sampleResult.calories);
      expect(foodItem.protein, sampleResult.protein);
      expect(foodItem.nutriScore, 'B');
      expect(foodItem.source, 'ai_vision');
      expect(foodItem.isAi, isTrue);
    });

    test('fromMap handles missing fields with safe defaults', () {
      final emptyResult = NutritionAnalysisResult.fromMap(const {});
      expect(emptyResult.foodName, 'อาหารที่ตรวจจับได้');
      expect(emptyResult.calories, 0.0);
      expect(emptyResult.healthScore, 'เกรด B');
      expect(emptyResult.confidence, 0.9);
    });
  });
}
