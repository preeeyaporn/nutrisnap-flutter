import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/auth/presentation/screens/login_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

void main() {
  Widget createTestWidget({AuthProvider? authProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              authProvider ??
              AuthProvider(authService: FirebaseAuthServiceImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NutritionProvider(repository: NutriSnapRepositoryImpl()),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all login screen UI components correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Brand headers
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(
        find.text('เข้าสู่ระบบเพื่อติดตามโภชนาการและสุขภาพของคุณ'),
        findsOneWidget,
      );

      // Google Account profile badge
      expect(find.text('ปรียาภรณ์ นาคสมบูรณ์'), findsOneWidget);
      expect(find.text('preeyapornnr@gmail.com'), findsOneWidget);

      // Google sign-in button
      expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);

      // Guest mode button
      expect(
        find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping guest mode signs in and navigates to MainShellScreen',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final guestBtn = find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)');
        await tester.ensureVisible(guestBtn);
        await tester.tap(guestBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Should be on MainShellScreen with HomeScreen
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping sign in with Google signs in and navigates to MainShellScreen',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final googleBtn = find.text('เข้าสู่ระบบด้วย Google');
        await tester.ensureVisible(googleBtn);
        await tester.tap(googleBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Should be on MainShellScreen with HomeScreen
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
      },
    );
  });
}
