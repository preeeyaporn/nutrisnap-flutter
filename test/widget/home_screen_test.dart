import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/home/presentation/screens/home_screen.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

void main() {
  Widget createTestWidget({
    String displayName = 'ปรียาภรณ์',
    void Function(int)? onNavigateTab,
  }) {
    final mockUser = UserModel(
      id: 'test_user_1',
      email: 'preeyaporn@nutrisnap.com',
      displayName: displayName,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );

    final authService = FirebaseAuthServiceImpl(initialUser: mockUser);
    final authProvider = AuthProvider(authService: authService);
    final nutritionProvider = NutritionProvider(repository: NutriSnapRepositoryImpl());

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<NutritionProvider>.value(value: nutritionProvider),
      ],
      child: MaterialApp(
        home: HomeScreen(onNavigateTab: onNavigateTab),
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('renders all Figma Home screen visual elements and greeting with dynamic user name', (tester) async {
      await tester.pumpWidget(createTestWidget(displayName: 'ปรียาภรณ์'));
      await tester.pumpAndSettle();

      // Top bar
      expect(find.text('NutriSnap'), findsOneWidget);
      expect(find.text('หน้าหลัก'), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);

      // Greeting with user name
      expect(find.textContaining('ปรียาภรณ์ ! 👋'), findsOneWidget);
      expect(find.text('ซิงค์คลาวด์แล้ว'), findsOneWidget);

      // Summary Card (0 meals initially)
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('แคลอรี่ที่บันทึก'), findsOneWidget);
      expect(find.text('โปรตีน 0ก.'), findsOneWidget);
      expect(find.text('คาร์บ 0ก.'), findsOneWidget);
      expect(find.text('ไขมัน 0ก.'), findsOneWidget);
      expect(find.text('0 มื้อ'), findsOneWidget);

      // Quick action cards
      expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
      expect(find.text('เชื่อมต่อ Open Food Facts API'), findsOneWidget);
      expect(find.text('สแกน'), findsOneWidget);

      expect(find.text('วิเคราะห์ภาพอาหารด้วย AI'), findsOneWidget);
      expect(find.text('เทคโนโลยี Gemini AI Vision'), findsOneWidget);
      expect(find.text('ถ่ายภาพ'), findsOneWidget);

      // Recent meals section (Empty state initially)
      expect(find.text('มื้ออาหารล่าสุด'), findsOneWidget);
      expect(find.text('ดูทั้งหมด >'), findsOneWidget);
      expect(find.text('ยังไม่มีมื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('สแกนบาร์โค้ดหรือถ่ายภาพอาหารเพื่อเริ่มต้นติดตามสารอาหารของคุณ'), findsOneWidget);
    });

    testWidgets('renders real recorded meals and calculates total calories accurately', (tester) async {
      final repo = NutriSnapRepositoryImpl();
      final item = FoodItem(
        id: 'real_food_1',
        name: 'ข้าวผัดกุ้ง',
        calories: 550,
        protein: 25,
        carbohydrates: 70,
        fat: 15,
        source: 'barcode_scan',
        scannedAt: DateTime.now(),
      );
      await repo.saveFoodItem(item);

      final authService = FirebaseAuthServiceImpl(
        initialUser: UserModel(
          id: 'u1',
          email: 'u1@test.com',
          displayName: 'ปรียาภรณ์',
          createdAt: DateTime.now(),
        ),
      );
      final authProvider = AuthProvider(authService: authService);
      final nutritionProvider = NutritionProvider(repository: repo);
      await nutritionProvider.loadRecentScans();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<NutritionProvider>.value(value: nutritionProvider),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify real calculated summary card
      expect(find.text('1 มื้อ'), findsOneWidget);
      expect(find.text('550'), findsOneWidget);
      expect(find.text('โปรตีน 25ก.'), findsOneWidget);
      expect(find.text('คาร์บ 70ก.'), findsOneWidget);
      expect(find.text('ไขมัน 15ก.'), findsOneWidget);

      // Verify real meal item appears
      expect(find.text('ข้าวผัดกุ้ง'), findsOneWidget);
      expect(find.text('550 แคล  •  โปรตีน 25ก.'), findsOneWidget);

      // Tapping real meal opens NutritionDetailScreen
      final mealTile = find.text('ข้าวผัดกุ้ง');
      await tester.ensureVisible(mealTile);
      await tester.tap(mealTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('ข้อมูลโภชนาการฉบับเต็ม'), findsOneWidget);
    });

    testWidgets('tapping view all calls onNavigateTab(1)', (tester) async {
      int? navigatedIndex;
      await tester.pumpWidget(createTestWidget(onNavigateTab: (idx) => navigatedIndex = idx));
      await tester.pumpAndSettle();

      final viewAll = find.text('ดูทั้งหมด >');
      await tester.ensureVisible(viewAll);
      await tester.tap(viewAll);
      await tester.pumpAndSettle();

      expect(navigatedIndex, equals(1));
    });
  });
}
