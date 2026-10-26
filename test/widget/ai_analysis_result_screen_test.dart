import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/camera/presentation/screens/ai_analysis_result_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/meal_detail_screen.dart';

void main() {
  final initialAnalysis = NutritionAnalysisResult(
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
    analyzedAt: DateTime(2026, 10, 8, 12, 30),
  );

  Widget createTestWidget({NutritionAnalysisResult? analysis}) {
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
        home: AiAnalysisResultScreen(analysis: analysis ?? initialAnalysis),
      ),
    );
  }

  group('AiAnalysisResultScreen Widget Tests (Screen 8)', () {
    testWidgets('renders all Figma Screen 8 elements accurately', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('รายละเอียดอาหาร'), findsOneWidget);

      // Top Badges
      expect(
        find.textContaining('ความแม่นยำ 94% • Gemini Vision API'),
        findsOneWidget,
      );
      expect(find.text('ตรวจสอบแล้ว'), findsOneWidget);

      // Food card
      expect(find.text('ผลวิเคราะห์ Gemini AI'), findsOneWidget);
      expect(find.textContaining('ข้าวกะเพราไก่ไข่ดาว'), findsWidgets);

      // Warning Note
      expect(
        find.textContaining('ข้อมูลโภชนาการเป็นค่าประมาณ'),
        findsOneWidget,
      );

      // Calories & Macros
      expect(find.text('560'), findsOneWidget);
      expect(find.text('กิโลแคลอรี่'), findsOneWidget);
      expect(find.text('โปรตีน'), findsOneWidget);
      expect(find.text('32 ก.'), findsOneWidget);
      expect(find.text('คาร์โบไฮเดรต'), findsOneWidget);
      expect(find.text('54 ก.'), findsOneWidget);
      expect(find.text('ไขมัน'), findsOneWidget);
      expect(find.text('24 ก.'), findsOneWidget);

      // Ingredients
      expect(find.text('ส่วนผสมที่ระบุได้'), findsOneWidget);
      expect(find.text('อกไก่ (150 กรัม)'), findsOneWidget);
      expect(find.text('ไข่ดาว (1 ฟอง)'), findsOneWidget);

      // Action buttons
      expect(find.text('บันทึกมื้ออาหารลงไดอารี่'), findsOneWidget);
      expect(find.text('ถ่ายภาพใหม่อีกครั้ง'), findsOneWidget);
    });

    testWidgets('recalculates nutrition when user enters corrected food name', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the correction card to expand it
      final expandCard = find.text('ไม่ใช่เมนูที่คุณสั่งใช่ไหม?');
      expect(expandCard, findsOneWidget);
      await tester.tap(expandCard);
      await tester.pumpAndSettle();

      // Now the text field and recalculate button should be visible
      expect(find.text('พิมพ์ชื่ออาหารจริงที่คุณสั่ง:'), findsOneWidget);
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Clear and enter "ข้าวมันไก่"
      await tester.enterText(textField, 'ข้าวมันไก่');
      await tester.pumpAndSettle();

      // Tap the recalculate button
      final recalcButton = find.text('ให้ Gemini คำนวณสารอาหารใหม่');
      expect(recalcButton, findsOneWidget);
      await tester.tap(recalcButton);

      // Pump to trigger async recalculate
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify that recalculation updated the food and calories
      expect(find.textContaining('ข้าวมันไก่'), findsWidgets);
      expect(find.textContaining('เรียบร้อยแล้ว'), findsOneWidget);
    });

    testWidgets(
      'tapping save button navigates to Screen 10 (MealDetailScreen)',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final saveButton = find.text('บันทึกมื้ออาหารลงไดอารี่');
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();

        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // MealDetailScreen (Screen 10) elements should appear
        expect(find.byType(MealDetailScreen), findsOneWidget);
        expect(find.text('สแกนและยืนยันแล้ว'), findsOneWidget);
        expect(find.text('พลังงานที่ได้รับ'), findsOneWidget);
      },
    );
  });
}
