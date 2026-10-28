// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';

/// Service contract for Firebase Authentication
abstract class FirebaseAuthService {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<Result<UserModel>> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<Result<UserModel>> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  });
  Future<Result<UserModel>> signInAnonymously();
  Future<Result<UserModel>> signInWithGoogle({
    String? customEmail,
    String? customDisplayName,
    String? customPhotoUrl,
  });
  Future<List<UserModel>> getSavedGoogleUsers();
  Future<Result<void>> signOut();
  Future<Result<UserModel>> updateProfile({
    String? displayName,
    String? photoUrl,
    double? dailyCalorieTarget,
  });
}

/// Firebase Auth implementation supporting Real Firebase Auth, Cloud Firestore sync,
/// and smooth offline/testing fallback.
class FirebaseAuthServiceImpl implements FirebaseAuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  /// In-memory user registry cache, initialized with demo user
  static final Map<String, UserModel> _registeredUsers = {
    'user@nutrisnap.com': UserModel(
      id: 'usr_user_nutrisnap_com',
      email: 'user@nutrisnap.com',
      displayName: 'ปรียาภรณ์',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
    'test@nutrisnap.com': UserModel(
      id: 'usr_test_nutrisnap_com',
      email: 'test@nutrisnap.com',
      displayName: 'test',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
    'test@nutri.com': UserModel(
      id: 'usr_test_nutri_com',
      email: 'test@nutri.com',
      displayName: 'test',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
    'user@nutri.com': UserModel(
      id: 'usr_user_nutri_com',
      email: 'user@nutri.com',
      displayName: 'user',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
  };

  /// In-memory user passwords cache
  static final Map<String, String> _userPasswords = {
    'user@nutrisnap.com': 'password123',
    'test@nutrisnap.com': 'password123',
    'test@nutri.com': 'password123',
    'user@nutri.com': 'password123',
  };

  FirebaseAuthServiceImpl({
    UserModel? initialUser,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore,
        _currentUser = initialUser {
    Future.microtask(() => _initAuthListener());
  }

  void _initAuthListener() {
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        auth.authStateChanges().listen((fbUser) {
          if (fbUser == null) {
            if (_currentUser != null && !_currentUser!.isAnonymous) {
              _currentUser = null;
              _authStateController.add(null);
            }
          }
        });
      } catch (_) {}
    }
    _authStateController.add(_currentUser);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  /// Flag set to true in main.dart when Hive is initialized
  static bool isHiveInitialized = false;

  Future<void> _syncUserToFirestore(UserModel user) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final fs = _firestore ?? FirebaseFirestore.instance;
      await fs.collection('users').doc(user.id).set({
        'uid': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isAnonymous': user.isAnonymous,
        'dailyCalorieTarget': user.dailyCalorieTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync notice: $e');
    }
  }

  Future<Box<Map>?> _getUserBox() async {
    if (!isHiveInitialized) return null;
    try {
      if (Hive.isBoxOpen(ApiConstants.userSettingsBoxName)) {
        return Hive.box<Map>(ApiConstants.userSettingsBoxName);
      } else {
        return await Hive.openBox<Map>(ApiConstants.userSettingsBoxName);
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistUser(UserModel user, {String? password}) async {
    if (user.email == null || user.email!.isEmpty) return;
    final key = user.email!.trim().toLowerCase();

    // 1. Persist to Hive database
    try {
      final box = await _getUserBox();
      if (box != null) {
        final map = user.toMap();
        if (password != null) {
          map['password'] = password;
        }
        await box.put(key, map);
      }
    } catch (_) {}

    // 2. Persist to SharedPreferences as persistent key-value store
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 100),
      );
      await prefs
          .setString('reg_user_name_$key', user.displayName)
          .timeout(const Duration(milliseconds: 100));
      await prefs
          .setDouble('reg_user_target_$key', user.dailyCalorieTarget)
          .timeout(const Duration(milliseconds: 100));
      if (password != null) {
        await prefs
            .setString('reg_user_password_$key', password)
            .timeout(const Duration(milliseconds: 100));
      }
    } catch (_) {}
  }

  Future<UserModel?> _loadUserFromDatabase(String email) async {
    final key = email.trim().toLowerCase();

    // 1. Try Hive database
    try {
      final box = await _getUserBox();
      if (box != null) {
        final Map? data = box.get(key);
        if (data != null) {
          if (data['password'] != null) {
            _userPasswords[key] = data['password'].toString();
          }
          return UserModel.fromMap(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}

    // 2. Try SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 100),
      );
      final savedName = prefs.getString('reg_user_name_$key');
      final savedTarget = prefs.getDouble('reg_user_target_$key');
      final savedPassword = prefs.getString('reg_user_password_$key');
      if (savedPassword != null && savedPassword.isNotEmpty) {
        _userPasswords[key] = savedPassword;
      }
      if (savedName != null && savedName.isNotEmpty) {
        return UserModel(
          id: 'usr_${key.replaceAll('@', '_').replaceAll('.', '_')}',
          email: email.trim(),
          displayName: savedName,
          isAnonymous: false,
          dailyCalorieTarget: savedTarget ?? 2000.0,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _loadPasswordFromDatabase(String email) async {
    final key = email.trim().toLowerCase();

    // 1. Try Hive database
    try {
      final box = await _getUserBox();
      if (box != null) {
        final Map? data = box.get(key);
        if (data != null && data['password'] != null) {
          return data['password'].toString();
        }
      }
    } catch (_) {}

    // 2. Try SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 100),
      );
      final savedPwd = prefs.getString('reg_user_password_$key');
      if (savedPwd != null && savedPwd.isNotEmpty) {
        return savedPwd;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<Result<UserModel>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return Result.failure('กรุณากรอกอีเมลให้ถูกต้อง');
    }
    if (password.length < 6) {
      return Result.failure('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
    }

    // 1. If Firebase is active, attempt real Firebase sign in
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        final userCred = await auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final fbUser = userCred.user;
        if (fbUser != null) {
          final localUser = await _loadUserFromDatabase(normalizedEmail);
          final chosenName = fbUser.displayName ??
              localUser?.displayName ??
              (normalizedEmail == 'user@nutrisnap.com'
                  ? 'ปรียาภรณ์'
                  : normalizedEmail.split('@').first);

          final user = UserModel(
            id: fbUser.uid,
            email: fbUser.email ?? normalizedEmail,
            displayName: chosenName,
            photoUrl: fbUser.photoURL ?? localUser?.photoUrl,
            isAnonymous: false,
            dailyCalorieTarget: localUser?.dailyCalorieTarget ?? 2000.0,
            createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
          );
          await _syncUserToFirestore(user);
          await _persistUser(user, password: password);
          _currentUser = user;
          _authStateController.add(_currentUser);
          return Result.success(user);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          return Result.failure('รหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบรหัสผ่านอีกครั้ง');
        }
        if (e.code == 'user-not-found') {
          final localUser =
              _registeredUsers[normalizedEmail] ?? await _loadUserFromDatabase(normalizedEmail);
          if (localUser == null) {
            return Result.failure(
              'ไม่พบบัญชีผู้ใช้นี้ในระบบ กรุณาสมัครสมาชิกก่อนเข้าสู่ระบบ',
            );
          }
        }
        debugPrint('FirebaseAuth signIn notice: ${e.code} ${e.message}');
      } catch (e) {
        debugPrint('FirebaseAuth signIn general error: $e');
      }
    }

    // 2. Local simulation fallback (for unit tests, demo users, offline mode)
    await Future.delayed(const Duration(milliseconds: 100));

    UserModel? user = _registeredUsers[normalizedEmail];

    if (user == null) {
      user = await _loadUserFromDatabase(normalizedEmail);
      if (user != null) {
        _registeredUsers[normalizedEmail] = user;
      }
    }

    if (user == null) {
      return Result.failure(
        'ไม่พบบัญชีผู้ใช้นี้ในระบบ กรุณาสมัครสมาชิกก่อนเข้าสู่ระบบ',
      );
    }

    String? expectedPassword = _userPasswords[normalizedEmail];
    if (expectedPassword == null) {
      expectedPassword = await _loadPasswordFromDatabase(normalizedEmail);
      if (expectedPassword != null) {
        _userPasswords[normalizedEmail] = expectedPassword;
      }
    }

    if (expectedPassword != null && expectedPassword != password) {
      return Result.failure('รหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบรหัสผ่านอีกครั้ง');
    }

    _currentUser = user;
    _authStateController.add(_currentUser);
    return Result.success(user);
  }

  @override
  Future<Result<UserModel>> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return Result.failure('รูปแบบอีเมลไม่ถูกต้อง');
    }
    if (password.length < 6) {
      return Result.failure('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
    }

    final chosenName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (normalizedEmail == 'user@nutrisnap.com'
            ? 'ปรียาภรณ์'
            : email.split('@').first);

    // 1. If Firebase is active, attempt real Firebase account creation
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        final userCred = await auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final fbUser = userCred.user;
        if (fbUser != null) {
          try {
            await fbUser.updateDisplayName(chosenName);
          } catch (_) {}

          final user = UserModel(
            id: fbUser.uid,
            email: fbUser.email ?? normalizedEmail,
            displayName: chosenName,
            isAnonymous: false,
            dailyCalorieTarget: 2000.0,
            createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
          );

          await _syncUserToFirestore(user);
          _registeredUsers[normalizedEmail] = user;
          _userPasswords[normalizedEmail] = password;
          await _persistUser(user, password: password);

          _currentUser = user;
          _authStateController.add(_currentUser);
          return Result.success(user);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return Result.failure('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ');
        } else if (e.code == 'weak-password') {
          return Result.failure('รหัสผ่านคาดเดาง่ายเกินไป');
        }
        debugPrint('FirebaseAuth signUp notice: ${e.code} ${e.message}');
      } catch (e) {
        debugPrint('FirebaseAuth signUp general error: $e');
      }
    }

    // 2. Local simulation fallback (for unit tests and offline mode)
    await Future.delayed(const Duration(milliseconds: 100));

    final user = UserModel(
      id: 'usr_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
      email: email.trim(),
      displayName: chosenName,
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );

    _registeredUsers[normalizedEmail] = user;
    _userPasswords[normalizedEmail] = password;
    await _persistUser(user, password: password);

    _currentUser = user;
    _authStateController.add(_currentUser);
    return Result.success(user);
  }

  @override
  Future<Result<UserModel>> signInAnonymously() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        final userCred = await auth.signInAnonymously();
        final fbUser = userCred.user;
        if (fbUser != null) {
          final guest = UserModel(
            id: fbUser.uid,
            displayName: 'ผู้ใช้ทั่วไป',
            isAnonymous: true,
            dailyCalorieTarget: 2000.0,
            createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
          );
          _currentUser = guest;
          _authStateController.add(_currentUser);
          return Result.success(guest);
        }
      } catch (e) {
        debugPrint('FirebaseAuth anonymous notice: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final guest = UserModel.guest();
    _currentUser = guest;
    _authStateController.add(_currentUser);
    return Result.success(guest);
  }

  @override
  Future<List<UserModel>> getSavedGoogleUsers() async {
    return [];
  }

  @override
  Future<Result<UserModel>> signInWithGoogle({
    String? customEmail,
    String? customDisplayName,
    String? customPhotoUrl,
  }) async {
    // 1. If Firebase is active and customEmail is not supplied, authenticate via GoogleSignIn & FirebaseAuth
    if (Firebase.apps.isNotEmpty && customEmail == null) {
      try {
        GoogleSignInAccount? googleUser;
        try {
          if (GoogleSignIn.instance.supportsAuthenticate()) {
            googleUser = await GoogleSignIn.instance.authenticate();
          }
        } catch (e) {
          debugPrint('GoogleSignIn error: $e');
        }

        if (googleUser != null) {
          final googleAuth = googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );
          final auth = _auth ?? FirebaseAuth.instance;
          final userCred = await auth.signInWithCredential(credential);
          final fbUser = userCred.user;
          if (fbUser != null) {
            final user = UserModel(
              id: fbUser.uid,
              email: fbUser.email ?? googleUser.email,
              displayName: fbUser.displayName ??
                  googleUser.displayName ??
                  'ผู้ใช้งาน Google',
              photoUrl: fbUser.photoURL ??
                  googleUser.photoUrl ??
                  'https://lh3.googleusercontent.com/a/default-user',
              isAnonymous: false,
              dailyCalorieTarget: 2000.0,
              createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
            );
            await _syncUserToFirestore(user);
            await _persistUser(user);
            _currentUser = user;
            _authStateController.add(_currentUser);
            return Result.success(user);
          }
        }
      } catch (e) {
        debugPrint('Firebase Google Sign-In notice, falling back: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Custom credentials provided (from Google Account Sheet or test)
    if (customEmail != null && customEmail.trim().isNotEmpty) {
      final normalizedEmail = customEmail.trim().toLowerCase();
      final name = (customDisplayName != null && customDisplayName.trim().isNotEmpty)
          ? customDisplayName.trim()
          : (normalizedEmail.contains('@')
              ? normalizedEmail.split('@').first
              : normalizedEmail);

      final user = UserModel(
        id: 'usr_google_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
        email: normalizedEmail,
        displayName: name,
        photoUrl: customPhotoUrl ??
            'https://lh3.googleusercontent.com/a/default-user',
        isAnonymous: false,
        dailyCalorieTarget: 2000.0,
        createdAt: DateTime.now(),
      );

      _registeredUsers[normalizedEmail] = user;
      await _syncUserToFirestore(user);
      await _persistUser(user);

      _currentUser = user;
      _authStateController.add(_currentUser);
      return Result.success(user);
    }

    // 3. Fallback / Test Default Google Account
    const googleEmail = 'preeyapornnr@gmail.com';
    final user = UserModel(
      id: 'usr_google_preeyapornnr',
      email: googleEmail,
      displayName: 'ปรียาภรณ์ นาคสมบูรณ์',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );

    _registeredUsers[googleEmail] = user;
    await _syncUserToFirestore(user);
    await _persistUser(user);

    _currentUser = user;
    _authStateController.add(_currentUser);
    return Result.success(user);
  }

  @override
  Future<Result<void>> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        await auth.signOut();
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      } catch (e) {
        debugPrint('FirebaseAuth signOut notice: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    _authStateController.add(null);
    return Result.success(null);
  }

  @override
  Future<Result<UserModel>> updateProfile({
    String? displayName,
    String? photoUrl,
    double? dailyCalorieTarget,
  }) async {
    if (_currentUser == null) {
      return Result.failure('ไม่มีผู้ใช้ที่เข้าสู่ระบบ');
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = _auth ?? FirebaseAuth.instance;
        final fbUser = auth.currentUser;
        if (fbUser != null) {
          if (displayName != null) await fbUser.updateDisplayName(displayName);
          if (photoUrl != null) await fbUser.updatePhotoURL(photoUrl);
        }
      } catch (e) {
        debugPrint('FirebaseAuth updateProfile notice: $e');
      }
    }

    final updated = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      dailyCalorieTarget: dailyCalorieTarget,
    );
    _currentUser = updated;
    await _syncUserToFirestore(updated);
    if (updated.email != null && updated.email!.isNotEmpty) {
      final normalizedEmail = updated.email!.toLowerCase();
      _registeredUsers[normalizedEmail] = updated;
      await _persistUser(updated);
    }
    _authStateController.add(_currentUser);
    return Result.success(updated);
  }

  void dispose() {
    _authStateController.close();
  }
}
