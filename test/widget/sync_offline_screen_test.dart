import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/sync/presentation/screens/sync_offline_screen.dart';

void main() {
  late HiveFoodRepository localRepo;
  late NutriSnapRepositoryImpl repository;
  late NutritionProvider provider;

  setUp(() async {
    localRepo = HiveFoodRepository();
    await localRepo.clearAll();

    repository = NutriSnapRepositoryImpl(localRepository: localRepo);
    provider = NutritionProvider(repository: repository);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<NutritionProvider>.value(
        value: provider,
        child: const SyncOfflineScreen(),
      ),
    );
  }

  group('SyncOfflineScreen Widget Tests', () {
    testWidgets('renders all visual elements matching Figma Screen 2', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('สถานะการซิงค์'), findsOneWidget);
      expect(find.text('รายการที่แคชไว้ในเครื่อง'), findsOneWidget);
      expect(find.text('ซิงค์ข้อมูลเมื่อออนไลน์'), findsOneWidget);
      expect(find.text('เข้าสู่ไดอารี่ออฟไลน์ต่อ'), findsOneWidget);
    });

    testWidgets('renders cached food items with images and sync status', (tester) async {
      final item = FoodItem(
        id: 'sync_item_1',
        name: 'ข้าวผัดกุ้ง',
        calories: 520,
        protein: 24,
        carbohydrates: 60,
        fat: 16,
        source: 'ai_vision',
        scannedAt: DateTime.now(),
        isSynced: true,
      );
      await localRepo.saveFoodItem(item);
      await provider.loadRecentScans();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('ข้าวผัดกุ้ง'), findsOneWidget);
      expect(find.text('520 kcal'), findsOneWidget);
      expect(find.text('ซิงค์แล้ว'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });
  });
}
