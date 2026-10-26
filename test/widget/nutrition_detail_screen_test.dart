import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/nutrition/presentation/screens/nutrition_detail_screen.dart';

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
    nutriScore: 'A',
    scannedAt: DateTime(2026, 9, 24),
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
      child: MaterialApp(home: NutritionDetailScreen(item: testItem)),
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

    testWidgets('tapping save to log shows confirmation toast', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final buttonFinder = find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'บันทึก "น้ำมะพร้าวสดออร์แกนิก 100%" ในบันทึกอาหารแล้ว',
        ),
        findsOneWidget,
      );
    });
  });
}
