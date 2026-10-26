import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
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
      child: const MaterialApp(home: OnboardingScreen()),
    );
  }

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders Figma Screen 2 components', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NutriSnap'), findsOneWidget);
      expect(find.text('ข้าม'), findsOneWidget);
      expect(find.text('เพื่อนคู่คิดด้านสุขภาพของคุณ'), findsOneWidget);
      expect(find.text('วิเคราะห์สารอาหารอย่างชาญฉลาด'), findsOneWidget);
      expect(find.text('ฐานข้อมูล Open Food Facts API'), findsOneWidget);
      expect(find.text('เครื่องสแกนบาร์โค้ดอัจฉริยะ'), findsOneWidget);

      // Nutrient tags
      expect(find.text('แคลอรี่'), findsOneWidget);
      expect(find.text('โปรตีน'), findsOneWidget);
      expect(find.text('คาร์โบไฮเดรต'), findsOneWidget);
      expect(find.text('ไขมัน'), findsOneWidget);
      expect(find.text('น้ำตาล'), findsOneWidget);

      // Step text
      expect(find.text('ขั้นตอน 1 จาก 3'), findsOneWidget);
      expect(find.text('ฟีเจอร์ถัดไป'), findsOneWidget);
    });

    testWidgets('tapping Next advances step to 2', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ฟีเจอร์ถัดไป'));
      await tester.pumpAndSettle();

      expect(find.text('ขั้นตอน 2 จาก 3'), findsOneWidget);
      expect(find.text('ถ่ายภาพเพื่อวิเคราะห์ด้วย Gemini AI'), findsOneWidget);
    });

    testWidgets('tapping skip navigates to LoginScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ข้าม'));
      await tester.pumpAndSettle();

      // Should land on LoginScreen
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(
        find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'),
        findsOneWidget,
      );
    });
  });
}
