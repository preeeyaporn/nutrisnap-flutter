import 'package:flutter/foundation.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/data/repositories/nutrisnap_repository_impl.dart';

enum ScanStatus { idle, scanning, success, error }

class NutritionProvider extends ChangeNotifier {
  final NutriSnapRepositoryImpl _repository;

  List<FoodItem> _recentScans = [];
  FoodItem? _currentProduct;
  NutritionAnalysisResult? _currentAiAnalysis;
  ScanStatus _scanStatus = ScanStatus.idle;
  String? _errorMessage;
  bool _isLoading = false;

  NutritionProvider({NutriSnapRepositoryImpl? repository})
      : _repository = repository ?? NutriSnapRepositoryImpl() {
    loadRecentScans();
  }

  List<FoodItem> get recentScans => _recentScans;
  FoodItem? get currentProduct => _currentProduct;
  NutritionAnalysisResult? get currentAiAnalysis => _currentAiAnalysis;
  ScanStatus get scanStatus => _scanStatus;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> loadRecentScans() async {
    final result = await _repository.getRecentScans();
    result.when(
      success: (items) {
        _recentScans = items;
        notifyListeners();
      },
      failure: (msg, ex) {
        // Non-blocking error
      },
    );
  }

  Future<bool> scanBarcode(String barcode) async {
    _scanStatus = ScanStatus.scanning;
    _errorMessage = null;
    _currentProduct = null;
    notifyListeners();

    final result = await _repository.getFoodItemByBarcode(barcode);

    return result.when(
      success: (item) {
        if (item != null) {
          _currentProduct = item;
          _scanStatus = ScanStatus.success;
          loadRecentScans();
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'ไม่พบข้อมูลสินค้าสำหรับบาร์โค้ดนี้';
          _scanStatus = ScanStatus.error;
          notifyListeners();
          return false;
        }
      },
      failure: (message, exception) {
        _errorMessage = message;
        _scanStatus = ScanStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> analyzeFoodImage(
    List<int> imageBytes, {
    String? userNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.analyzeFoodImage(
      imageBytes: imageBytes,
      userNotes: userNotes,
    );

    _isLoading = false;
    return result.when(
      success: (analysis) {
        _currentAiAnalysis = analysis;
        _currentProduct = analysis.toFoodItem();
        loadRecentScans();
        notifyListeners();
        return true;
      },
      failure: (msg, ex) {
        _errorMessage = msg;
        notifyListeners();
        return false;
      },
    );
  }

  void setCurrentProduct(FoodItem item) {
    _currentProduct = item;
    notifyListeners();
  }

  void clearCurrentProduct() {
    _currentProduct = null;
    _currentAiAnalysis = null;
    _scanStatus = ScanStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadRecentScans();
  }

  Future<void> deleteFoodItem(String id) async {
    await _repository.deleteFoodItem(id);
    if (_currentProduct?.id == id) {
      _currentProduct = null;
    }
    await loadRecentScans();
  }

  Future<bool> saveFoodItem(FoodItem item) async {
    final result = await _repository.saveFoodItem(item);
    if (result.isSuccess) {
      await loadRecentScans();
      return true;
    }
    return false;
  }

  Future<bool> syncCloud() async {
    final result = await _repository.syncLocalToCloud();
    return result.isSuccess;
  }
}
