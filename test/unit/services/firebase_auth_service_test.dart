import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';

void main() {
  group('FirebaseAuthService Tests', () {
    late FirebaseAuthServiceImpl authService;

    setUp(() {
      authService = FirebaseAuthServiceImpl();
    });

    tearDown(() {
      authService.dispose();
    });

    test('Initial user is null', () {
      expect(authService.currentUser, isNull);
    });

    test(
      'signInWithEmailAndPassword succeeds with valid email & password',
      () async {
        final result = await authService.signInWithEmailAndPassword(
          'test@nutrisnap.com',
          'password123',
        );

        expect(result.isSuccess, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, 'test@nutrisnap.com');
        expect(authService.currentUser?.displayName, 'test');
      },
    );

    test(
      'signInWithEmailAndPassword fails with invalid email or short password',
      () async {
        final invalidEmail = await authService.signInWithEmailAndPassword(
          'invalid_email',
          'password123',
        );
        expect(invalidEmail.isFailure, isTrue);

        final shortPassword = await authService.signInWithEmailAndPassword(
          'valid@test.com',
          '123',
        );
        expect(shortPassword.isFailure, isTrue);
      },
    );

    test('signUpWithEmailAndPassword creates new user', () async {
      final result = await authService.signUpWithEmailAndPassword(
        'newuser@nutrisnap.com',
        'secretPass',
        displayName: 'Somchai Nutri',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.displayName, 'Somchai Nutri');
      expect(result.dataOrNull?.isAnonymous, isFalse);
    });

    test('signInAnonymously logs in as guest', () async {
      final result = await authService.signInAnonymously();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isAnonymous, isTrue);
      expect(result.dataOrNull?.displayName, 'ผู้ใช้ทั่วไป');
    });

    test('signOut clears current user', () async {
      await authService.signInAnonymously();
      expect(authService.currentUser, isNotNull);

      await authService.signOut();
      expect(authService.currentUser, isNull);
    });

    test('updateProfile updates user target and info', () async {
      await authService.signInWithEmailAndPassword(
        'user@nutri.com',
        'password123',
      );

      final updateRes = await authService.updateProfile(
        displayName: 'Updated Name',
        dailyCalorieTarget: 2500.0,
      );

      expect(updateRes.isSuccess, isTrue);
      expect(authService.currentUser?.displayName, 'Updated Name');
      expect(authService.currentUser?.dailyCalorieTarget, 2500.0);
    });

    test('updateProfile fails when no user is signed in', () async {
      final result = await authService.updateProfile(displayName: 'Test');
      expect(result.isFailure, isTrue);
    });

    test(
      'signInWithEmailAndPassword retrieves original registered name for returning user',
      () async {
        final signUpRes = await authService.signUpWithEmailAndPassword(
          'registered_user@nutrisnap.com',
          'password123',
          displayName: 'ปรียาภรณ์ แสนดี',
        );
        expect(signUpRes.isSuccess, isTrue);

        await authService.signOut();
        expect(authService.currentUser, isNull);

        final signInRes = await authService.signInWithEmailAndPassword(
          'registered_user@nutrisnap.com',
          'password123',
        );
        expect(signInRes.isSuccess, isTrue);
        expect(authService.currentUser?.displayName, 'ปรียาภรณ์ แสนดี');
      },
    );

    test(
      'signInWithEmailAndPassword fails when account is not registered',
      () async {
        final result = await authService.signInWithEmailAndPassword(
          'not_registered@nutrisnap.com',
          'password123',
        );
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, contains('ไม่พบบัญชีผู้ใช้นี้ในระบบ'));
      },
    );

    test(
      'signInWithEmailAndPassword fails when password is incorrect',
      () async {
        final result = await authService.signInWithEmailAndPassword(
          'user@nutrisnap.com',
          'wrongpassword999',
        );
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, contains('รหัสผ่านไม่ถูกต้อง'));
      },
    );

    test('signInWithGoogle signs in with Google user', () async {
      final result = await authService.signInWithGoogle();
      expect(result.isSuccess, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'preeyapornnr@gmail.com');
      expect(authService.currentUser?.displayName, contains('ปรียาภรณ์ นาคสมบูรณ์'));
      expect(authService.currentUser?.isAnonymous, isFalse);
    });
  });
}
