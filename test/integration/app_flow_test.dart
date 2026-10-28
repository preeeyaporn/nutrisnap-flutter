import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NutriSnap End-to-End Application Flow Integration Tests', () {
    testWidgets('Full flow: Splash -> Onboarding -> Google Login -> Main Shell -> History & Sync Tabs', (tester) async {
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

      // 5. Enter via Google Login
      final googleBtn = find.text('เข้าสู่ระบบด้วย Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // 6. Main App Shell loaded (Default Home Screen)
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
      expect(find.textContaining('ปรียาภรณ์ นาคสมบูรณ์'), findsWidgets);

      // 7. Navigate to History Tab
      final historyTab = find.text('ประวัติ');
      await tester.tap(historyTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ประวัติมื้ออาหาร'), findsOneWidget);

      // 8. Navigate to Sync Offline Tab
      final syncTab = find.text('ซิงค์ข้อมูล');
      await tester.tap(syncTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('สถานะการซิงค์'), findsOneWidget);
      expect(find.text('ความสามารถของอุปกรณ์ขณะออฟไลน์'), findsOneWidget);

      // 9. Navigate back to Home Tab
      final homeTab = find.text('หน้าหลัก').last;
      await tester.tap(homeTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 10. Tap "สแกน" button on Home Screen to open Barcode Scanner
      final scanActionBtn = find.widgetWithText(ElevatedButton, 'สแกน');
      expect(scanActionBtn, findsOneWidget);
      await tester.tap(scanActionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('ระบบตรวจจับบาร์โค้ดสด'), findsOneWidget);
      expect(find.text('8850188800123'), findsOneWidget);

      // 11. Tap "ดูข้อมูลโภชนาการฉบับเต็ม"
      final detailBtn = find.text('ดูข้อมูลโภชนาการฉบับเต็ม');
      await tester.tap(detailBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 12. Verify Nutrition Detail Screen
      expect(find.text('ข้อมูลโภชนาการฉบับเต็ม'), findsOneWidget);
      expect(find.text('น้ำมะพร้าวสดออร์แกนิก 100%'), findsWidgets);
      expect(find.text('สารอาหารหลัก (Macronutrients)'), findsOneWidget);
      expect(find.text('บันทึกลงสมุดบันทึกอาหารประจำวัน'), findsOneWidget);

      // 13. Tap Save to Log
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
      'Guest Mode flow: Enter as Guest -> Barcode Scan triggers Guest Locked Dialog',
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

        // In Login Screen, tap "เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)"
        final guestBtn = find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)');
        await tester.ensureVisible(guestBtn);
        await tester.tap(guestBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Home Screen loaded as Guest
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.textContaining('ผู้ใช้ทั่วไป'), findsOneWidget);

        // Tap "สแกน" to open Barcode Scanner
        final scanActionBtn = find.widgetWithText(ElevatedButton, 'สแกน');
        await tester.tap(scanActionBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Attempt to tap "ดูข้อมูลโภชนาการฉบับเต็ม"
        final detailBtn = find.text('ดูข้อมูลโภชนาการฉบับเต็ม');
        await tester.tap(detailBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Should show locked dialog for guest mode
        expect(find.text('เฉพาะสมาชิกเท่านั้น'), findsOneWidget);
        expect(find.textContaining('โหมดผู้เยี่ยมชมไม่สามารถสแกนบาร์โค้ดได้'), findsOneWidget);
      },
    );

    testWidgets(
      'Google Login flow: Authenticates via Google and shows ปรียาภรณ์ นาคสมบูรณ์',
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

        // Navigate to Login via Start -> Skip
        await tester.tap(find.text('เริ่มต้นใช้งาน'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('ข้าม'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // In Login Screen, tap "เข้าสู่ระบบด้วย Google"
        final googleBtn = find.text('เข้าสู่ระบบด้วย Google');
        await tester.ensureVisible(googleBtn);
        await tester.tap(googleBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Home Screen loaded with user name "ปรียาภรณ์ นาคสมบูรณ์"
        expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
        expect(find.textContaining('ปรียาภรณ์ นาคสมบูรณ์'), findsWidgets);
        expect(find.text('ซิงค์คลาวด์แล้ว'), findsOneWidget);
      },
    );
  });
}
