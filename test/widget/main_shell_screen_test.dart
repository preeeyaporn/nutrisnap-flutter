import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/home/presentation/screens/main_shell_screen.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';

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
      child: const MaterialApp(home: MainShellScreen()),
    );
  }

  group('MainShellScreen Widget Tests', () {
    testWidgets('renders bottom navigation with 4 tabs and switches', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check bottom navigation tabs and header
      expect(find.text('หน้าหลัก'), findsNWidgets(2));
      expect(find.text('ประวัติ'), findsOneWidget);
      expect(find.text('ซิงค์ข้อมูล'), findsOneWidget);
      expect(find.text('ตั้งค่า'), findsOneWidget);

      // Verify Home tab is active by default
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);

      // Switch to History tab
      await tester.tap(find.text('ประวัติ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ประวัติการสแกนและโภชนาการ'), findsOneWidget);

      // Switch to Sync tab
      await tester.tap(find.text('ซิงค์ข้อมูล'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Cloud Firestore Synchronization'), findsOneWidget);

      // Switch to Settings/Profile tab
      await tester.tap(find.text('ตั้งค่า'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('โปรไฟล์และตั้งค่า'), findsOneWidget);
      expect(find.text('Gemini API Integration'), findsOneWidget);
      expect(find.text('ออกจากระบบ'), findsOneWidget);
    });

    testWidgets('sign out dialog confirms and navigates to LoginScreen', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Profile/Settings tab
      await tester.tap(find.text('ตั้งค่า'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to sign out button and tap
      final logoutTile = find.text('ออกจากระบบ');
      await tester.ensureVisible(logoutTile);
      await tester.tap(logoutTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog should be visible
      expect(find.text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'), findsOneWidget);

      // Confirm sign out
      final confirmBtn = find.widgetWithText(TextButton, 'ออกจากระบบ');
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Navigated to LoginScreen
      expect(find.text('ยินดีต้อนรับกลับสู่ NutriSnap'), findsOneWidget);
      expect(
        find.text('เข้าใช้งานแบบผู้เยี่ยมชม (Guest Mode)'),
        findsOneWidget,
      );
    });
  });
}
