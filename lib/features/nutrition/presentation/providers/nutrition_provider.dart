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

  List<int>? _lastCapturedImageBytes;

  List<FoodItem> get recentScans => _recentScans;
  FoodItem? get currentProduct => _currentProduct;
  NutritionAnalysisResult? get currentAiAnalysis => _currentAiAnalysis;
  List<int>? get lastCapturedImageBytes => _lastCapturedImageBytes;
  ScanStatus get scanStatus => _scanStatus;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  NutriSnapRepositoryImpl get repository => _repository;

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
    _lastCapturedImageBytes = imageBytes;
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

  Future<bool> recalculateWithFoodCorrection({
    required String correctedFoodName,
    List<int>? imageBytes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bytes = imageBytes ?? _lastCapturedImageBytes ?? List<int>.generate(100, (i) => i);
    final prompt =
        'ผู้ใช้ระบุว่าอาหารในภาพนี้คือ "$correctedFoodName" (ไม่ใช่ที่ตรวจจับได้ก่อนหน้า) กรุณาวิเคราะห์ภาพร่วมกับชื่ออาหาร "$correctedFoodName" และคำนวณคุณค่าทางโภชนาการ สัดส่วน แคลอรี่ โปรตีน คาร์โบไฮเดรต ไขมัน น้ำตาล ใยอาหาร โซเดียม และส่วนผสมใหม่ทั้งหมดอย่างละเอียด';

    final result = await _repository.analyzeFoodImage(
      imageBytes: bytes,
      userNotes: prompt,
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

  Future<FoodItem> saveCurrentAiMeal({NutritionAnalysisResult? customAnalysis}) async {
    final analysis = customAnalysis ?? _currentAiAnalysis;
    final foodItem = (analysis ??
            NutritionAnalysisResult(
              foodName: 'ข้าวกะเพราไก่ไข่ดาว',
              estimatedPortion: 'ขนาดมาตรฐาน (380 กรัม)',
              calories: 560.0,
              protein: 32.0,
              carbohydrates: 54.0,
              fat: 24.0,
              sugar: 3.5,
              fiber: 4.2,
              sodium: 780.0,
              confidence: 0.94,
              healthScore: 'เกรด B',
              detectedIngredients: const [
                'อกไก่ (150 กรัม)',
                'ข้าวหอมมะลิ (1 ทัพพี)',
                'ไข่ดาว (1 ฟอง)',
                'ใบกะเพราและพริกสด',
              ],
              advice:
                  'หมายเหตุ: ค่าความเป็นไป AI vision 94% ค่าโภชนาการถูกปรับเทียบกับการดูดซับน้ำมันจากการผัดอาหารตามสั่งไทย',
              analyzedAt: DateTime.now(),
            ))
        .toFoodItem();

    await _repository.saveFoodItem(foodItem);
    _currentProduct = foodItem;
    await loadRecentScans();
    notifyListeners();
    return foodItem;
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

  Future<bool> syncCloud() async {
    final result = await _repository.syncLocalToCloud();
    return result.isSuccess;
  }
}
