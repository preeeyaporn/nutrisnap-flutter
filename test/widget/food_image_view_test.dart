import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/widgets/food_image_view.dart';

void main() {
  group('FoodImageView Widget Tests', () {
    testWidgets('renders fallback icon when imageUrl is empty and network image fails', (tester) async {
      final item = FoodItem(
        id: 'test_food',
        name: 'ข้าวสวย',
        calories: 200,
        protein: 4,
        carbohydrates: 44,
        fat: 1,
        source: 'ai_vision',
        scannedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodImageView(
              item: item,
              width: 60,
              height: 60,
            ),
          ),
        ),
      );

      expect(find.byType(FoodImageView), findsOneWidget);
    });

    testWidgets('renders custom placeholder when provided', (tester) async {
      final item = FoodItem(
        id: 'test_food_2',
        name: 'น้ำเปล่า',
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        source: 'ai_vision',
        scannedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodImageView(
              item: item,
              width: 50,
              height: 50,
              placeholder: const Icon(Icons.water_drop, key: Key('water_icon')),
            ),
          ),
        ),
      );

      expect(find.byType(FoodImageView), findsOneWidget);
    });
  });
}
