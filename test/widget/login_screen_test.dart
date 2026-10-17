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
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all login screen UI components correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Brand headers
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsWidgets); // App bar title & button
      expect(find.text('เข้าสู่ระบบเพื่อติดตามโภชนาการและสุขภาพของคุณ'), findsOneWidget);

      // Form input fields
      expect(find.text('อีเมลของคุณ'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);

      // Forgot password link
      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);

      // Guest mode button
      expect(find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'), findsOneWidget);

      // Register link
      expect(find.text('ยังไม่มีบัญชีใช่หรือไม่?'), findsOneWidget);
      expect(find.text('สมัครสมาชิกทันที'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear the default demo text fields
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '');
      await tester.enterText(textFields.at(1), '');
      await tester.pumpAndSettle();

      // Tap login button
      final loginBtn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalid-email');
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
    });

    testWidgets('tapping guest mode signs in and navigates to MainShellScreen', (tester) async {
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
    });

    testWidgets('tapping sign in with valid credentials navigates to MainShellScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Navigates to main screen with HomeScreen
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
    });

    testWidgets('navigates to RegisterScreen when tapping register link', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final registerLink = find.text('สมัครสมาชิกทันที');
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Should be on RegisterScreen
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่านอีกครั้ง'), findsOneWidget);
      expect(find.text('เป้าหมายด้านสุขภาพของคุณ'), findsOneWidget);
    });
  });
}
