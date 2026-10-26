import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/meal_detail_screen.dart';

void main() {
  final testFood = FoodItem(
    id: 'meal_screen10_test_1',
    name: 'ข้าวกะเพราไก่ไข่ดาว',
    calories: 560.0,
    protein: 32.0,
    carbohydrates: 54.0,
    fat: 24.0,
    sugar: 3.5,
    fiber: 4.2,
    sodium: 780.0,
    servingSize: 'ขนาดมาตรฐาน (380 กรัม)',
    nutriScore: 'B',
    scannedAt: DateTime(2026, 10, 24, 12, 30),
    ingredients: [
      'อกไก่ (150 กรัม)',
      'ข้าวหอมมะลิ (1 ทัพพี)',
      'ไข่ดาว (1 ฟอง)',
      'ใบกะเพราและพริกสด',
    ],
  );

  final testAnalysis = NutritionAnalysisResult(
    foodName: 'ข้าวกะเพราไก่ไข่ดาว',
    estimatedPortion: 'ขนาดมาตรฐาน (380 กรัม)',
    calories: 560.0,
    protein: 32.0,
    carbohydrates: 54.0,
    fat: 24.0,
    sugar: 3.5,
    fiber: 4.2,
    sodium: 780.0,
    confidence: 0.94,
    healthScore: 'เกรด B',
    detectedIngredients: [
      'อกไก่ (150 กรัม)',
      'ข้าวหอมมะลิ (1 ทัพพี)',
      'ไข่ดาว (1 ฟอง)',
      'ใบกะเพราและพริกสด',
    ],
    advice:
        'หมายเหตุ: ค่าโภชนาการถูกปรับเทียบกับการดูดซับน้ำมันจากการผัดอาหารตามสั่งไทย',
    analyzedAt: DateTime(2026, 10, 24, 12, 30),
  );

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: FirebaseAuthServiceImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NutritionProvider(repository: NutriSnapRepositoryImpl()),
        ),
      ],
      child: MaterialApp(
        home: MealDetailScreen(item: testFood, analysisResult: testAnalysis),
      ),
    );
  }

  group('MealDetailScreen Widget Tests (Screen 10)', () {
    testWidgets('renders all Figma Screen 10 elements accurately', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('รายละเอียดอาหาร'), findsOneWidget);
      expect(find.text('สแกนและยืนยันแล้ว'), findsOneWidget);

      // Food Title & Info Card
      expect(find.text('ข้าวกะเพราไก่ไข่ดาว'), findsWidgets);
      expect(find.textContaining('ตรงกัน 94%'), findsOneWidget);

      // Energy summary
      expect(find.text('พลังงานที่ได้รับ'), findsOneWidget);
      expect(find.text('560'), findsOneWidget);
      expect(find.textContaining('แคลอรี่'), findsWidgets);
      expect(find.text('ยอดโควตาต่อวัน'), findsOneWidget);
      expect(find.text('28%'), findsOneWidget);

      // Macronutrient breakdown
      expect(find.text('สัดส่วนสารอาหารหลัก'), findsOneWidget);
      expect(find.text('โปรตีน'), findsWidgets);
      expect(find.text('32.0 ก.'), findsOneWidget);
      expect(find.text('คาร์โบไฮเดรต'), findsWidgets);
      expect(find.text('54.0 ก.'), findsOneWidget);
      expect(find.text('ไขมันรวม'), findsWidgets);
      expect(find.text('24.0 ก.'), findsOneWidget);
      expect(find.text('น้ำตาล'), findsWidgets);
      expect(find.text('3.5 ก.'), findsOneWidget);

      // Fiber & Sodium
      expect(find.text('ใยอาหาร'), findsOneWidget);
      expect(find.text('4.2 ก.'), findsOneWidget);
      expect(find.text('โซเดียม'), findsOneWidget);
      expect(find.text('780 มก.'), findsOneWidget);

      // Ingredients
      expect(find.text('ส่วนผสมที่ระบุได้'), findsOneWidget);
      expect(find.text('อกไก่ (150 กรัม)'), findsOneWidget);

      // System & Sync info
      expect(find.text('ระบบบันทึกและซิงค์ข้อมูล'), findsOneWidget);
      expect(find.text('Gemini 1.5 Flash Vision'), findsOneWidget);
      expect(find.text('สถานะการจัดเก็บ'), findsOneWidget);

      // Action buttons
      expect(find.text('แก้ไขข้อมูลมื้อนี้'), findsOneWidget);
      expect(find.text('ลบรายการอาหารนี้'), findsOneWidget);
    });

    testWidgets('tapping edit button opens edit dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the pencil icon in the top header
      final editIcon = find.byIcon(Icons.edit_outlined);
      expect(editIcon, findsOneWidget);

      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('แก้ไขข้อมูลมื้ออาหาร'), findsOneWidget);
      expect(find.text('ชื่ออาหาร'), findsOneWidget);
      expect(find.text('ปริมาณ / สัดส่วน'), findsOneWidget);
      expect(find.text('พลังงาน (กิโลแคลอรี่)'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('แก้ไขข้อมูลมื้ออาหาร'), findsNothing);
    });

    testWidgets('tapping delete button opens delete confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the top delete button
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded).first;
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.text('ลบรายการอาหาร?'), findsOneWidget);
      expect(
        find.textContaining('คุณต้องการลบ "ข้าวกะเพราไก่ไข่ดาว"'),
        findsOneWidget,
      );

      // Cancel dialog
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('ลบรายการอาหาร?'), findsNothing);
    });
  });
}
