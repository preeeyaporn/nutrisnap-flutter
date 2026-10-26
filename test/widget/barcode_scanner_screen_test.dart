import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/scanner/presentation/screens/barcode_scanner_screen.dart';

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
      child: const MaterialApp(home: BarcodeScannerScreen()),
    );
  }

  group('BarcodeScannerScreen Widget Tests', () {
    testWidgets('renders Figma Screen 4 elements accurately', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Top live detection badge
      expect(find.text('ระบบตรวจจับบาร์โค้ดสด'), findsOneWidget);

      // Reticle hint
      expect(find.text('จัดบาร์โค้ดให้อยู่ในกรอบ'), findsOneWidget);

      // Search card
      expect(find.text('การค้นหาสด'), findsOneWidget);

      // Action buttons
      expect(find.text('อัปโหลดรูปภาพ'), findsOneWidget);
      expect(find.text('พิมพ์รหัสบาร์โค้ด'), findsOneWidget);

      // Bottom scanned result card
      expect(find.text('สแกนสำเร็จแล้ว'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);
      expect(find.text('8850188800123'), findsOneWidget);
      expect(find.text('พร้อมดึงข้อมูลโภชนาการ'), findsOneWidget);

      // CTA button
      expect(find.text('ดูข้อมูลโภชนาการฉบับเต็ม'), findsOneWidget);

      // Tip banner
      expect(
        find.textContaining('คำแนะนำ: ถือกล้องนิ่งห่างประมาณ 10–15 ซม.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping manual barcode button opens input dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('พิมพ์รหัสบาร์โค้ด'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('พิมพ์รหัสบาร์โค้ด'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ค้นหา'), findsOneWidget);
    });
  });
}
