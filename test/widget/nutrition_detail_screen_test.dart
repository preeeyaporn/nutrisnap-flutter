import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';

class MockOpenFoodFactsService extends Mock implements OpenFoodFactsService {}

void main() {
  final testItem = FoodItem(
    id: 'detail_test_item',
    barcode: '8850188800123',
    name: 'น้ำมะพร้าวสดออร์แกนิก 100%',
    brand: 'Nature Choice',
    servingSize: '330 มล.',
    calories: 65,
    protein: 1.2,
    carbohydrates: 15.0,
    fat: 0.2,
    sugar: 12.0,
    fiber: 1.5,
    saturatedFat: 0.1,
    sodium: 15.0,
    nutriScore: 'A',
    scannedAt: DateTime(2026, 9, 24),
    ingredients: const ['น้ำมะพร้าวออร์แกนิก 100%', 'วิตามินซีธรรมชาติ'],
  );

  Widget createTestWidget({
    FoodItem? item,
    OpenFoodFactsService? offService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: FirebaseAuthServiceImpl())),
        ChangeNotifierProvider(create: (_) => NutritionProvider(repository: NutriSnapRepositoryImpl())),
      ],
      child: MaterialApp(
        home: NutritionDetailScreen(
          item: item ?? testItem,
          openFoodFactsService: offService,
        ),
      ),
    );
  }

  group('NutritionDetailScreen Widget Tests', () {
    testWidgets('renders all nutrition facts and charts', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ข้อมูลโภชนาการฉบับเต็ม'), findsOneWidget);
      expect(find.text('น้ำมะพร้าวสดออร์แกนิก 100%'), findsOneWidget);
      expect(find.text('เกรด A'), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
      expect(find.text('กิโลแคลอรี่ (kcal)'), findsOneWidget);

      // Macronutrients
      expect(find.text('โปรตีน (Protein)'), findsOneWidget);
      expect(find.text('คาร์โบไฮเดรต (Carbohydrates)'), findsOneWidget);
      expect(find.text('ไขมันรวม (Total Fat)'), findsOneWidget);
      expect(find.text('น้ำตาล (Sugar)'), findsOneWidget);

      // AI insight
      expect(find.text('บทวิเคราะห์จาก Gemini AI'), findsOneWidget);

      // CTA
      expect(find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน'), findsOneWidget);
    });

    testWidgets('calculates and renders daily calorie percentage correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 65 kcal / 2000 kcal = 3.25% ≈ 3.3%
      expect(
        find.textContaining('คิดเป็น 3.3% ของความต้องการพลังงานต่อวัน (2000 kcal)'),
        findsOneWidget,
      );
      expect(find.text('อาหารว่าง / เครื่องดื่ม (พลังงานเบาๆ)'), findsOneWidget);
      expect(find.textContaining('เหลือโควตาพลังงานสำหรับวันนี้อีก 1935 kcal'), findsOneWidget);
    });

    testWidgets('renders macronutrient progress bars and Thai RDI percentages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check macro values
      expect(find.text('1.2 กรัม'), findsOneWidget);
      expect(find.text('15.0 กรัม'), findsOneWidget);
      expect(find.text('0.2 กรัม'), findsOneWidget);
      expect(find.text('12.0 กรัม'), findsOneWidget);

      // Check RDI labels
      expect(find.textContaining('2.4% ของเกณฑ์ที่แนะนำต่อวัน (50 กรัม)'), findsOneWidget);
      expect(find.textContaining('5.0% ของเกณฑ์ที่แนะนำต่อวัน (300 กรัม)'), findsOneWidget);
      expect(find.textContaining('0.3% ของเกณฑ์ที่แนะนำต่อวัน (65 กรัม)'), findsOneWidget);
      expect(find.textContaining('50.0% ของเกณฑ์ที่แนะนำต่อวัน (ไม่เกิน 24 กรัม (6 ช้อนชา))'), findsOneWidget);

      // Energy distribution ratio
      expect(find.text('สัดส่วนการกระจายพลังงาน (Energy Ratio)'), findsOneWidget);
      expect(find.textContaining('โปรตีน'), findsWidgets);
      expect(find.textContaining('คาร์โบไฮเดรต'), findsWidgets);
      expect(find.textContaining('ไขมัน'), findsWidgets);

      // Micronutrients
      expect(find.text('ใยอาหาร (Fiber)'), findsOneWidget);
      expect(find.text('โซเดียม (Sodium)'), findsOneWidget);
      expect(find.text('1.5 g'), findsOneWidget);
      expect(find.text('15 mg'), findsOneWidget);
    });

    testWidgets('tapping save to log shows confirmation toast', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final buttonFinder = find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('บันทึก "น้ำมะพร้าวสดออร์แกนิก 100%" ในบันทึกอาหารแล้ว'), findsOneWidget);
    });

    testWidgets('refresh button fetches latest data from Open Food Facts API', (tester) async {
      final mockOff = MockOpenFoodFactsService();
      final updatedItem = testItem.copyWith(
        name: 'น้ำมะพร้าวสดออร์แกนิก 100% (ข้อมูลอัปเดต)',
        calories: 70.0,
      );

      when(() => mockOff.getProductByBarcode(any()))
          .thenAnswer((_) async => Result.success(updatedItem));

      await tester.pumpWidget(createTestWidget(offService: mockOff));
      await tester.pumpAndSettle();

      // Find refresh button in AppBar
      final refreshBtn = find.byTooltip('รีเฟรชข้อมูลจาก Open Food Facts');
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockOff.getProductByBarcode('8850188800123')).called(1);
      expect(find.text('น้ำมะพร้าวสดออร์แกนิก 100% (ข้อมูลอัปเดต)'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      expect(find.text('อัปเดตข้อมูลโภชนาการจาก Open Food Facts สำเร็จ'), findsOneWidget);
    });
  });
}
