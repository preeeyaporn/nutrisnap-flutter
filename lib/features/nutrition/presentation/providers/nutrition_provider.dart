import 'package:flutter/foundation.dart';
import 'package:nutrisnap/core/services/connectivity_checker.dart';
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

  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'barcode_scan', 'ai_vision', 'favorites'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'calories', 'nutriScore'
  bool _isOnline = true;
  bool _manualOverride = false;

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

  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String get sortBy => _sortBy;
  bool get isOnline => _isOnline;

  int get unsyncedCount => _recentScans.where((item) => !item.isSynced).length;

  double get totalCaloriesToday {
    final now = DateTime.now();
    return _recentScans
        .where((item) =>
            item.scannedAt.year == now.year &&
            item.scannedAt.month == now.month &&
            item.scannedAt.day == now.day)
        .fold(0.0, (sum, item) => sum + item.calories);
  }

  Map<String, double> get totalMacrosToday {
    final now = DateTime.now();
    final todayItems = _recentScans.where((item) =>
        item.scannedAt.year == now.year &&
        item.scannedAt.month == now.month &&
        item.scannedAt.day == now.day);

    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;

    for (final item in todayItems) {
      protein += item.protein;
      carbs += item.carbohydrates;
      fat += item.fat;
    }

    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  Map<String, int> get nutriScoreCounts {
    final counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0};
    for (final item in _recentScans) {
      final score = (item.nutriScore ?? 'A').toUpperCase();
      if (counts.containsKey(score)) {
        counts[score] = (counts[score] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<FoodItem> get filteredScans {
    var items = List<FoodItem>.from(_recentScans);

    // 1. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      items = items.where((item) =>
          item.name.toLowerCase().contains(q) ||
          item.brand.toLowerCase().contains(q) ||
          item.barcode.contains(q)).toList();
    }

    // 2. Category / Source Filter
    if (_selectedFilter == 'favorites') {
      items = items.where((item) => item.isFavorite).toList();
    } else if (_selectedFilter != 'all') {
      items = items.where((item) => item.source == _selectedFilter).toList();
    }

    // 3. Sorting
    switch (_sortBy) {
      case 'oldest':
        items.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
        break;
      case 'calories':
        items.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case 'nutriScore':
        items.sort((a, b) => (a.nutriScore ?? 'Z').compareTo(b.nutriScore ?? 'Z'));
        break;
      case 'newest':
      default:
        items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        break;
    }

    return items;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setOnlineStatus(bool online, {bool isManual = true}) {
    _manualOverride = isManual;
    _isOnline = online;
    notifyListeners();
  }

  Future<bool> checkRealConnectivity({bool force = false}) async {
    if (!force && _manualOverride) {
      return _isOnline;
    }
    final online = await ConnectivityChecker.checkInternet();
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
    return online;
  }

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

  Future<void> clearAllHistory() async {
    await _repository.clearAll();
    _currentProduct = null;
    await loadRecentScans();
  }

  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  Future<bool> syncCloud() async {
    final result = await _repository.syncLocalToCloud();
    if (result.isSuccess) {
      await loadRecentScans();
    }
    return result.isSuccess;
  }
}
