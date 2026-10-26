import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/auth/presentation/screens/register_screen.dart';
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
      child: const MaterialApp(home: RegisterScreen()),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all register screen UI elements correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('สมัครสมาชิก'), findsOneWidget);
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(find.text('เริ่มต้นกับ NutriSnap'), findsOneWidget);

      // Form labels
      expect(find.text('ชื่อ-นามสกุล หรือชื่อเล่น'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่านอีกครั้ง'), findsOneWidget);

      // Goal section & chips
      expect(find.text('เป้าหมายด้านสุขภาพของคุณ'), findsOneWidget);
      expect(find.text('ลดน้ำหนัก'), findsOneWidget);
      expect(find.text('เพิ่มกล้ามเนื้อ'), findsOneWidget);
      expect(find.text('รักษาสุขภาพ / ปรับสมดุล'), findsOneWidget);
      expect(find.text('ควบคุมน้ำตาล'), findsOneWidget);

      // Submit CTA
      expect(find.text('สมัครสมาชิกและเริ่มใช้งาน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'สมัครสมาชิกและเริ่มใช้งาน',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอกชื่อของคุณ'), findsOneWidget);
      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
      expect(find.text('กรุณายืนยันรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'สมชาย สุขภาพดี');
      await tester.enterText(textFields.at(1), 'somchai@nutrisnap.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'differentPassword');
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'สมัครสมาชิกและเริ่มใช้งาน',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'สมชาย สุขภาพดี');
      await tester.enterText(textFields.at(1), 'somchai@nutrisnap.com');
      await tester.enterText(textFields.at(2), '123');
      await tester.enterText(textFields.at(3), '123');
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'สมัครสมาชิกและเริ่มใช้งาน',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'), findsOneWidget);
    });

    testWidgets('allows selecting different dietary goals', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final muscleChip = find.text('เพิ่มกล้ามเนื้อ');
      await tester.ensureVisible(muscleChip);
      await tester.tap(muscleChip);
      await tester.pumpAndSettle();

      // Chip selection changed without error
      expect(muscleChip, findsOneWidget);
    });

    testWidgets('successful registration navigates to MainShellScreen', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'สมชาย ใจดี');
      await tester.enterText(textFields.at(1), 'somchai@test.com');
      await tester.enterText(textFields.at(2), 'securePass123');
      await tester.enterText(textFields.at(3), 'securePass123');
      await tester.pumpAndSettle();

      // Select 'ลดน้ำหนัก' goal
      final weightLossChip = find.text('ลดน้ำหนัก');
      await tester.ensureVisible(weightLossChip);
      await tester.tap(weightLossChip);
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'สมัครสมาชิกและเริ่มใช้งาน',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Main screen loaded with HomeScreen
      expect(find.text('มื้ออาหารที่บันทึกวันนี้'), findsOneWidget);
      expect(find.text('สแกนบาร์โค้ดผลิตภัณฑ์'), findsOneWidget);
    });
  });
}
