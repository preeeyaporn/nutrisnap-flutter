import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    late FirebaseAuthServiceImpl authService;
    late AuthProvider provider;

    setUp(() {
      authService = FirebaseAuthServiceImpl();
      provider = AuthProvider(authService: authService);
    });

    tearDown(() {
      authService.dispose();
      provider.dispose();
    });

    test('Initial state is not authenticated', () {
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('signInAsGuest logs in and updates state', () async {
      final ok = await provider.signInAsGuest();
      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.isAnonymous, isTrue);
    });

    test('signInWithEmail logs in and updates state', () async {
      final ok = await provider.signInWithEmail(
        'test@nutri.com',
        'password123',
      );
      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, 'test@nutri.com');
    });

    test('signInWithGoogle logs in and updates state with Google account', () async {
      final ok = await provider.signInWithGoogle();
      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.displayName, contains('ปรียาภรณ์'));
      expect(provider.currentUser?.email, 'preeyapornnr@gmail.com');
      expect(provider.currentUser?.isAnonymous, isFalse);
    });

    test('signOut logs out user', () async {
      await provider.signInAsGuest();
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });

    test('updateDailyCalorieTarget updates target', () async {
      await provider.signInWithEmail('user@nutri.com', 'password123');
      final ok = await provider.updateDailyCalorieTarget(2400.0);
      expect(ok, isTrue);
      expect(provider.currentUser?.dailyCalorieTarget, 2400.0);
    });
  });
}
