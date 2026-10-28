import 'package:flutter/foundation.dart';
import 'package:nutrisnap/core/services/firebase_auth_service.dart';
import 'package:nutrisnap/features/auth/domain/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({FirebaseAuthService? authService})
    : _authService = authService ?? FirebaseAuthServiceImpl() {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _currentUser = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithEmailAndPassword(
      email,
      password,
    );
    _isLoading = false;

    return result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
        return true;
      },
      failure: (message, exception) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signUpWithEmailAndPassword(
      email,
      password,
      displayName: displayName,
    );
    _isLoading = false;

    return result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
        return true;
      },
      failure: (message, exception) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> signInAsGuest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInAnonymously();
    _isLoading = false;

    return result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
        return true;
      },
      failure: (message, exception) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<List<UserModel>> getSavedGoogleUsers() async {
    return _authService.getSavedGoogleUsers();
  }

  Future<bool> signInWithGoogle({
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle(
      customEmail: email,
      customDisplayName: displayName,
      customPhotoUrl: photoUrl,
    );
    _isLoading = false;

    return result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
        return true;
      },
      failure: (message, exception) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    double? dailyCalorieTarget,
  }) async {
    if (_currentUser == null) return false;
    final result = await _authService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      dailyCalorieTarget: dailyCalorieTarget,
    );
    return result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
        return true;
      },
      failure: (message, exception) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> updateDailyCalorieTarget(double target) async {
    return updateProfile(dailyCalorieTarget: target);
  }
}
