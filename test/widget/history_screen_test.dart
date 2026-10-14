import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/features/history/presentation/screens/history_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

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
        child: const HistoryScreen(),
      ),
    );
  }

  group('HistoryScreen Widget Tests', () {
    testWidgets('renders all visual elements matching Figma Screen 1', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('ประวัติมื้ออาหาร'), findsOneWidget);
      expect(find.textContaining('ประวัติการรับประทาน'), findsOneWidget);
      expect(find.text('ตรวจสอบและปรับแต่งบันทึกโภชนาการของคุณ'), findsOneWidget);
    });

    testWidgets('renders history food cards and items correctly', (tester) async {
      final item = FoodItem(
        id: 'hist_1',
        name: 'นมสดเมจิ รสจืด',
        brand: 'CP Meiji',
        calories: 140,
        protein: 7,
        carbohydrates: 10,
        fat: 8,
        nutriScore: 'A',
        scannedAt: DateTime.now(),
        source: 'barcode_scan',
      );

      await localRepo.saveFoodItem(item);
      await provider.loadRecentScans();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('นมสดเมจิ รสจืด'), findsOneWidget);
      expect(find.text('140 กิโลแคลอรี่'), findsAtLeast(1));
    });
  });
}
