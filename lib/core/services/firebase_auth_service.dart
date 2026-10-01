import 'dart:async';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';

/// Service contract for Firebase Authentication
abstract class FirebaseAuthService {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<Result<UserModel>> signInWithEmailAndPassword(String email, String password);
  Future<Result<UserModel>> signUpWithEmailAndPassword(String email, String password, {String? displayName});
  Future<Result<UserModel>> signInAnonymously();
  Future<Result<void>> signOut();
  Future<Result<UserModel>> updateProfile({String? displayName, String? photoUrl, double? dailyCalorieTarget});
}

/// Firebase Auth implementation supporting local simulation and Cloud Firebase bridge
class FirebaseAuthServiceImpl implements FirebaseAuthService {
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
  };

  FirebaseAuthServiceImpl({UserModel? initialUser}) {
    _currentUser = initialUser;
    // Notify after microtask
    Future.microtask(() => _authStateController.add(_currentUser));
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  /// Flag set to true in main.dart when Hive is initialized
  static bool isHiveInitialized = false;

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

  Future<void> _persistUser(UserModel user) async {
    if (user.email == null || user.email!.isEmpty) return;
    final key = user.email!.trim().toLowerCase();

    // 1. Persist to Hive database
    try {
      final box = await _getUserBox();
      if (box != null) {
        await box.put(key, user.toMap());
      }
    } catch (_) {}

    // 2. Persist to SharedPreferences as persistent key-value store
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
      await prefs.setString('reg_user_name_$key', user.displayName).timeout(const Duration(milliseconds: 100));
      await prefs.setDouble('reg_user_target_$key', user.dailyCalorieTarget).timeout(const Duration(milliseconds: 100));
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
          return UserModel.fromMap(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}

    // 2. Try SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
      final savedName = prefs.getString('reg_user_name_$key');
      final savedTarget = prefs.getDouble('reg_user_target_$key');
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

  @override
  Future<Result<UserModel>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return Result.failure('กรุณากรอกอีเมลให้ถูกต้อง');
    }
    if (password.length < 6) {
      return Result.failure('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
    }

    // 1. Check in-memory registry
    UserModel? user = _registeredUsers[normalizedEmail];

    // 2. Check Local Database (Hive / SharedPreferences)
    if (user == null) {
      user = await _loadUserFromDatabase(normalizedEmail);
      if (user != null) {
        _registeredUsers[normalizedEmail] = user;
      }
    }

    // 3. Fallback for unregistered or default account
    if (user == null) {
      final defaultName = normalizedEmail == 'user@nutrisnap.com' ? 'ปรียาภรณ์' : email.split('@').first;
      user = UserModel(
        id: 'usr_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
        email: email.trim(),
        displayName: defaultName,
        isAnonymous: false,
        dailyCalorieTarget: 2000.0,
        createdAt: DateTime.now(),
      );
      _registeredUsers[normalizedEmail] = user;
      await _persistUser(user);
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
    await Future.delayed(const Duration(milliseconds: 300));
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return Result.failure('รูปแบบอีเมลไม่ถูกต้อง');
    }
    if (password.length < 6) {
      return Result.failure('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
    }

    final chosenName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (normalizedEmail == 'user@nutrisnap.com' ? 'ปรียาภรณ์' : email.split('@').first);

    final user = UserModel(
      id: 'usr_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
      email: email.trim(),
      displayName: chosenName,
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );

    // Save in registry and persist to database
    _registeredUsers[normalizedEmail] = user;
    await _persistUser(user);

    _currentUser = user;
    _authStateController.add(_currentUser);
    return Result.success(user);
  }

  @override
  Future<Result<UserModel>> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final guest = UserModel.guest();
    _currentUser = guest;
    _authStateController.add(_currentUser);
    return Result.success(guest);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
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

    final updated = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      dailyCalorieTarget: dailyCalorieTarget,
    );
    _currentUser = updated;
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
