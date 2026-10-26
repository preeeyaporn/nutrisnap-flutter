import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/features/nutrition/presentation/widgets/nutrition_badge.dart';

void main() {
  group('NutritionBadge Widget Tests', () {
    testWidgets('renders all nutrient badge types correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NutritionBadge(
                  label: 'แคลอรี่',
                  value: '250 kcal',
                  type: NutrientType.calories,
                ),
                NutritionBadge(
                  label: 'โปรตีน',
                  value: '20g',
                  type: NutrientType.protein,
                ),
                NutritionBadge(label: 'คาร์บ', type: NutrientType.carbs),
                NutritionBadge(label: 'ไขมัน', type: NutrientType.fat),
                NutritionBadge(label: 'น้ำตาล', type: NutrientType.sugar),
                NutritionBadge(label: 'ไฟเบอร์', type: NutrientType.fiber),
              ],
            ),
          ),
        ),
      );

      expect(find.text('แคลอรี่ 250 kcal'), findsOneWidget);
      expect(find.text('โปรตีน 20g'), findsOneWidget);
      expect(find.text('คาร์บ'), findsOneWidget);
      expect(find.text('ไขมัน'), findsOneWidget);
      expect(find.text('น้ำตาล'), findsOneWidget);
      expect(find.text('ไฟเบอร์'), findsOneWidget);
    });
  });
}
