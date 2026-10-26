import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/screens/register_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NutriSnap End-to-End Application Flow Integration Tests', () {
    testWidgets('Full flow: Splash -> Onboarding -> Scanner -> Detail Screen', (
      tester,
    ) async {
      // Configure 390x844 mobile viewport as specified in requirements
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = FirebaseAuthServiceImpl();
      final repo = NutriSnapRepositoryImpl();

      await tester.pumpWidget(
        NutriSnapApp(authService: auth, repository: repo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Splash Screen
      expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
      expect(find.text('ปัญญาประดิษฐ์ด้านโภชนาการ'), findsOneWidget);

      // 2. Navigate to Onboarding
      final startBtn = find.text('เริ่มต้นใช้งาน');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('วิเคราะห์สารอาหารอย่างชาญฉลาด'), findsOneWidget);
      expect(find.text('ฟีเจอร์ถัดไป'), findsOneWidget);

      // 3. Skip Onboarding to Login Screen
      final skipBtn = find.text('ข้าม');
      await tester.tap(skipBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Login Screen loaded
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(
        find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'),
        findsOneWidget,
      );

      // 5. Enter via Guest Mode
      final guestBtn = find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)');
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // 6. Main App Shell loaded (Default Home Screen)
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
      expect(find.textContaining('ผู้ใช้ทั่วไป'), findsOneWidget);

      // 7. Tap "สแกน" button on Home Screen to open Barcode Scanner
      final scanActionBtn = find.widgetWithText(ElevatedButton, 'สแกน');
      expect(scanActionBtn, findsOneWidget);
      await tester.tap(scanActionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('ระบบตรวจจับบาร์โค้ดสด'), findsOneWidget);
      expect(find.text('8850188800123'), findsOneWidget);

      // 6. Tap "ดูข้อมูลโภชนาการฉบับเต็ม"
      final detailBtn = find.text('ดูข้อมูลโภชนาการฉบับเต็ม');
      await tester.tap(detailBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 7. Verify Nutrition Detail Screen
      expect(find.text('ข้อมูลโภชนาการฉบับเต็ม'), findsOneWidget);
      expect(find.text('น้ำมะพร้าวสดออร์แกนิก 100%'), findsWidgets);
      expect(find.text('สารอาหารหลัก (Macronutrients)'), findsOneWidget);
      expect(find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน'), findsOneWidget);

      // 8. Tap Save to Log
      final saveBtn = find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน');
      await tester.ensureVisible(saveBtn);
      ScaffoldMessenger.of(tester.element(saveBtn)).clearSnackBars();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('ในบันทึกอาหารแล้ว'), findsOneWidget);
    });

    testWidgets(
      'Registration flow: Register with name -> Home Screen -> Displays greeting with user name',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = FirebaseAuthServiceImpl();
        final repo = NutriSnapRepositoryImpl();

        await tester.pumpWidget(
          NutriSnapApp(authService: auth, repository: repo),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Skip Splash & Onboarding to Login
        await tester.tap(find.text('เริ่มต้นใช้งาน'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('ข้าม'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // In Login Screen, tap "สมัครสมาชิกทันที"
        final registerNavBtn = find.text('สมัครสมาชิกทันที');
        await tester.ensureVisible(registerNavBtn);
        await tester.tap(registerNavBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Register Screen loaded
        expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);

        // Enter Registration details
        final regFields = find.descendant(
          of: find.byType(RegisterScreen),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(regFields.at(0), 'ปรียาภรณ์');
        await tester.enterText(regFields.at(1), 'user@nutrisnap.com');
        await tester.enterText(regFields.at(2), 'password123');
        await tester.enterText(regFields.at(3), 'password123');
        await tester.pump();

        // Submit registration
        final submitBtn = find.text('สมัครสมาชิกและเริ่มใช้งาน');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Home Screen loaded with user's registered name in the greeting!
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.textContaining('ปรียาภรณ์'), findsWidgets);
        expect(find.text('ซิงค์คลาวด์แล้ว'), findsOneWidget);
      },
    );

    testWidgets(
      'Returning user login: Pulls registered name from database into Home Screen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = FirebaseAuthServiceImpl();
        final repo = NutriSnapRepositoryImpl();

        // Pre-register user in database with custom name using tester.runAsync so Future.delayed resolves
        await tester.runAsync(() async {
          await auth.signUpWithEmailAndPassword(
            'nong.nut@nutrisnap.com',
            'pass12345',
            displayName: 'ณัชชา สายสุขภาพ',
          );
          await auth.signOut();
        });

        await tester.pumpWidget(
          NutriSnapApp(authService: auth, repository: repo),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Navigate to Login via Start -> Skip
        await tester.tap(find.text('เริ่มต้นใช้งาน'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('ข้าม'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // In Login Screen, enter registered email & password
        final emailField = find.byType(TextFormField).at(0);
        final passField = find.byType(TextFormField).at(1);
        await tester.enterText(emailField, 'nong.nut@nutrisnap.com');
        await tester.enterText(passField, 'pass12345');
        await tester.pump();

        // Tap Login
        final loginBtn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
        await tester.ensureVisible(loginBtn);
        await tester.tap(loginBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Home Screen loaded and retrieved the original registered name "ณัชชา สายสุขภาพ" from database!
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.textContaining('ณัชชา สายสุขภาพ'), findsWidgets);
        // And verify summary card is 0 meals
        expect(find.text('0 มื้อ'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('ยังไม่มีมื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      },
    );
  });
}
