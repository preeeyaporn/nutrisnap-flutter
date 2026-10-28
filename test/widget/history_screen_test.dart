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
      expect(find.text('บันทึกแล้ว 4 มื้อ'), findsOneWidget);
      expect(find.text('🍴 ทั้งหมด (4)'), findsOneWidget);
      expect(find.text('║█║ บาร์โค้ด (2)'), findsOneWidget);
      expect(find.text('✨ กล้อง AI (2)'), findsOneWidget);
      expect(find.textContaining('12:30 น. • มื้อเที่ยง'), findsOneWidget);
      expect(find.textContaining('08:15 น. • มื้อเช้า'), findsOneWidget);
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

    testWidgets('filters accurately between barcode and AI vision with automatic calorie summary', (tester) async {
      final now = DateTime.now();
      final barcodeItem = FoodItem(
        id: 'hist_barcode',
        name: 'นมสดเมจิ รสจืด',
        brand: 'CP Meiji',
        calories: 140,
        protein: 7,
        carbohydrates: 10,
        fat: 8,
        nutriScore: 'A',
        scannedAt: now,
        source: 'barcode_scan',
      );
      final aiItem = FoodItem(
        id: 'hist_ai',
        name: 'ข้าวกะเพราไก่',
        brand: 'Homemade',
        calories: 550,
        protein: 28,
        carbohydrates: 50,
        fat: 18,
        nutriScore: 'B',
        scannedAt: now,
        source: 'ai_vision',
      );

      await localRepo.saveFoodItem(barcodeItem);
      await localRepo.saveFoodItem(aiItem);
      await provider.loadRecentScans();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Initially 'all' filter: 2 meals, 690 kcal (140 + 550)
      expect(find.text('บันทึกแล้ว 2 มื้อ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('690 กิโลแคลอรี่'),
        ),
        findsOneWidget,
      );
      expect(find.text('140 kcal'), findsOneWidget);
      expect(find.text('550 kcal'), findsOneWidget);
      expect(find.text('🍴 ทั้งหมด (2)'), findsOneWidget);
      expect(find.text('║█║ บาร์โค้ด (1)'), findsOneWidget);
      expect(find.text('✨ กล้อง AI (1)'), findsOneWidget);
      expect(find.text('นมสดเมจิ รสจืด'), findsOneWidget);
      expect(find.text('ข้าวกะเพราไก่'), findsOneWidget);

      // Tap '║█║ บาร์โค้ด (1)' filter pill
      await tester.tap(find.text('║█║ บาร์โค้ด (1)'));
      await tester.pumpAndSettle();

      // Now filtered to barcode only: 1 meal, 140 kcal
      expect(find.text('บันทึกแล้ว 1 มื้อ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('รวม 140 กิโลแคลอรี่'),
        ),
        findsOneWidget,
      );
      expect(find.text('นมสดเมจิ รสจืด'), findsOneWidget);
      expect(find.text('ข้าวกะเพราไก่'), findsNothing);

      // Tap '✨ กล้อง AI (1)' filter pill
      await tester.tap(find.text('✨ กล้อง AI (1)'));
      await tester.pumpAndSettle();

      // Now filtered to AI camera only: 1 meal, 550 kcal
      expect(find.text('บันทึกแล้ว 1 มื้อ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('รวม 550 กิโลแคลอรี่'),
        ),
        findsOneWidget,
      );
      expect(find.text('นมสดเมจิ รสจืด'), findsNothing);
      expect(find.text('ข้าวกะเพราไก่'), findsOneWidget);
    });

    testWidgets('AI items with gemini_vision source render AI badge and appear in AI filter', (tester) async {
      final now = DateTime.now();
      final chickenMeal = FoodItem(
        id: 'ai_chicken_1',
        name: 'ปีกไก่ทอด',
        brand: 'Gemini 1.5 Flash Vision',
        calories: 650,
        protein: 30,
        carbohydrates: 12,
        fat: 42,
        nutriScore: 'C',
        scannedAt: now,
        source: 'gemini_vision',
      );

      await localRepo.saveFoodItem(chickenMeal);
      await provider.loadRecentScans();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('ปีกไก่ทอด'), findsOneWidget);
      expect(find.text('• ✨ AI ประมาณการ'), findsOneWidget);
      expect(find.text('✨ กล้อง AI (1)'), findsOneWidget);
    });
  });
}
