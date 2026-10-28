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

    // 3. Block login if user is not registered in the system
    if (user == null) {
      return Result.failure(
        'ไม่พบบัญชีผู้ใช้นี้ในระบบ กรุณาสมัครสมาชิกก่อนเข้าสู่ระบบ',
      );
    }

    // 4. Verify password
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
        : (normalizedEmail == 'user@nutrisnap.com'
              ? 'ปรียาภรณ์'
              : email.split('@').first);

    final user = UserModel(
      id: 'usr_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
      email: email.trim(),
      displayName: chosenName,
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime.now(),
    );

    // Save in registry and persist to database with password
    _registeredUsers[normalizedEmail] = user;
    _userPasswords[normalizedEmail] = password;
    await _persistUser(user, password: password);

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

  static final List<UserModel> _savedGoogleAccounts = [
    UserModel(
      id: 'usr_google_preeyapornnr',
      email: 'preeyapornnr@gmail.com',
      displayName: 'ปรียาภรณ์ นาคสมบูรณ์',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
      isAnonymous: false,
      dailyCalorieTarget: 2000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<List<UserModel>> getSavedGoogleUsers() async {
    final list = <UserModel>[..._savedGoogleAccounts];
    for (final u in _registeredUsers.values) {
      if (u.id.startsWith('usr_google_') && !list.any((x) => x.email == u.email)) {
        list.add(u);
      }
    }
    return list;
  }

  @override
  Future<Result<UserModel>> signInWithGoogle({
    String? customEmail,
    String? customDisplayName,
    String? customPhotoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. If custom credentials provided (from Google Account Chooser or test)
    if (customEmail != null && customEmail.trim().isNotEmpty) {
      final normalizedEmail = customEmail.trim().toLowerCase();
      final name = (customDisplayName != null && customDisplayName.trim().isNotEmpty)
          ? customDisplayName.trim()
          : (normalizedEmail.contains('@') ? normalizedEmail.split('@').first : normalizedEmail);

      final user = UserModel(
        id: 'usr_google_${normalizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
        email: normalizedEmail,
        displayName: name,
        photoUrl: customPhotoUrl ?? 'https://lh3.googleusercontent.com/a/default-user',
        isAnonymous: false,
        dailyCalorieTarget: 2000.0,
        createdAt: DateTime.now(),
      );

      _registeredUsers[normalizedEmail] = user;
      if (!_savedGoogleAccounts.any((x) => x.email == normalizedEmail)) {
        _savedGoogleAccounts.add(user);
      }
      await _persistUser(user);

      _currentUser = user;
      _authStateController.add(_currentUser);
      return Result.success(user);
    }

    // 2. Default Google account (ปรียาภรณ์ นาคสมบูรณ์) when called with no arguments
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
    await _persistUser(user);

    _currentUser = user;
    _authStateController.add(_currentUser);
    return Result.success(user);
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
