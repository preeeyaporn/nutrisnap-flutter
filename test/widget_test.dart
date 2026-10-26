import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';
import 'package:nutrisnap/main.dart';

void main() {
  testWidgets('NutriSnapApp launches and shows splash screen elements', (
    WidgetTester tester,
  ) async {
    final mockAuth = FirebaseAuthServiceImpl();
    final mockRepo = NutriSnapRepositoryImpl();

    await tester.pumpWidget(
      NutriSnapApp(authService: mockAuth, repository: mockRepo),
    );
    await tester.pumpAndSettle();

    expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
    expect(find.text('สแกนทันใจ'), findsOneWidget);
    expect(find.text('เรียลไทม์'), findsOneWidget);
    expect(find.text('แม่นยำ'), findsOneWidget);
  });
}
