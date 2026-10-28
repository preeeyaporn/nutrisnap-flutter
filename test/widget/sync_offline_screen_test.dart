import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:nutrisnap/features/sync/presentation/screens/sync_offline_screen.dart';

void main() {
  late HiveFoodRepository localRepo;
  late NutriSnapRepositoryImpl repository;
  late NutritionProvider provider;

  setUp(() async {
    localRepo = HiveFoodRepository();
    await localRepo.clearAll();

    repository = NutriSnapRepositoryImpl(localRepository: localRepo);
    provider = NutritionProvider(repository: repository);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<NutritionProvider>.value(
        value: provider,
        child: const SyncOfflineScreen(),
      ),
    );
  }

  group('SyncOfflineScreen Widget Tests', () {
    testWidgets('renders all visual elements matching Figma Screen 2', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('สถานะการซิงค์'), findsOneWidget);
      expect(find.text('ความสามารถของอุปกรณ์ขณะออฟไลน์'), findsOneWidget);
      expect(find.text('บันทึกมื้ออาหารแบบออฟไลน์'), findsOneWidget);
      expect(find.text('แคชข้อมูลบาร์โค้ด'), findsOneWidget);
      expect(find.text('Gemini AI & ซิงค์ข้อมูลคลาวด์'), findsOneWidget);
      expect(find.text('รายการที่แคชไว้ในเครื่อง'), findsOneWidget);
      expect(find.text('ซิงค์ข้อมูลเมื่อออนไลน์'), findsOneWidget);
      expect(find.text('เข้าสู่ไดอารี่ออฟไลน์ต่อ'), findsOneWidget);
    });
  });
}
