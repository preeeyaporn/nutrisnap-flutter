import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/splash/presentation/screens/splash_screen.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: FirebaseAuthServiceImpl())),
        ChangeNotifierProvider(create: (_) => NutritionProvider(repository: NutriSnapRepositoryImpl())),
      ],
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('renders all Figma Screen 1 visual elements correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Brand badge
      expect(find.text('ปัญญาประดิษฐ์ด้านโภชนาการ'), findsOneWidget);

      // Subtitle & tagline
      expect(find.text('โภชนาการอัจฉริยะ ปลายนิ้วสัมผัส'), findsOneWidget);

      // 3 feature cards
      expect(find.text('สแกนทันใจ'), findsOneWidget);
      expect(find.text('เรียลไทม์'), findsOneWidget);
      expect(find.text('แม่นยำ'), findsOneWidget);

      // Open Food Facts & Gemini API badge
      expect(find.text('ขับเคลื่อนโดย Open Food Facts & Gemini API'), findsOneWidget);

      // CTA Button
      expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // Login link
      expect(find.textContaining('มีบัญชีอยู่แล้วใช่หรือไม่?'), findsOneWidget);
    });

    testWidgets('tapping CTA button navigates to onboarding screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('เริ่มต้นใช้งาน'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should find onboarding screen content
      expect(find.text('ข้าม'), findsOneWidget);
      expect(find.text('ฟีเจอร์ถัดไป'), findsOneWidget);
    });

    testWidgets('tapping login link navigates directly to LoginScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final loginLink = find.textContaining('มีบัญชีอยู่แล้วใช่หรือไม่?');
      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should find login screen content
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'), findsOneWidget);
    });
  });
}
