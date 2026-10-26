import 'package:nutrisnap/core/database/cloud/firestore_food_repository.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Unified NutriSnap Repository coordinating Local (Hive), Cloud (Firestore),
/// Open Food Facts API, and Gemini AI Vision.
class NutriSnapRepositoryImpl implements FoodRepository {
  final FoodRepository _localRepository;
  final FoodRepository? cloudRepository;
  final OpenFoodFactsService _openFoodFactsService;
  final GeminiService _geminiService;

  NutriSnapRepositoryImpl({
    FoodRepository? localRepository,
    this.cloudRepository,
    OpenFoodFactsService? openFoodFactsService,
    GeminiService? geminiService,
  }) : _localRepository = localRepository ?? HiveFoodRepository(),
       _openFoodFactsService =
           openFoodFactsService ?? OpenFoodFactsServiceImpl(),
       _geminiService = geminiService ?? GeminiServiceImpl();

  void updateUserId(String newUserId) {
    final cloud = cloudRepository;
    if (cloud is FirestoreFoodRepository) {
      cloud.updateUserId(newUserId);
    }
  }

  void updateUserInfo({
    required String newUserId,
    String? email,
    String? displayName,
    double? dailyTarget,
  }) {
    final cloud = cloudRepository;
    if (cloud is FirestoreFoodRepository) {
      cloud.updateUserInfo(
        newUserId: newUserId,
        email: email,
        displayName: displayName,
        dailyTarget: dailyTarget,
      );
    }
  }

  GeminiService get geminiService => _geminiService;

  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async {
    // 1. Save to local database (Hive)
    final localResult = await _localRepository.saveFoodItem(item);
    if (localResult.isFailure) return localResult;

    // 2. Sync to Cloud Firestore if connected
    if (cloudRepository != null) {
      cloudRepository!.saveFoodItem(item).ignore();
    }

    return Result.success(null);
  }

  @override
  Future<Result<FoodItem?>> getFoodItemById(String id) async {
    // Check local database first
    final localResult = await _localRepository.getFoodItemById(id);
    if (localResult.isSuccess && localResult.dataOrNull != null) {
      return localResult;
    }

    // Fallback to Cloud if not found locally
    if (cloudRepository != null) {
      final cloudResult = await cloudRepository!.getFoodItemById(id);
      if (cloudResult.isSuccess && cloudResult.dataOrNull != null) {
        // Cache to local
        await _localRepository.saveFoodItem(cloudResult.dataOrNull!);
        return cloudResult;
      }
    }

    return localResult;
  }

  @override
  Future<Result<FoodItem?>> getFoodItemByBarcode(String barcode) async {
    // 1. Check local Hive cache
    final cached = await _localRepository.getFoodItemByBarcode(barcode);
    if (cached.isSuccess && cached.dataOrNull != null) {
      return cached;
    }

    // 2. Query Open Food Facts REST API
    final remoteResult = await _openFoodFactsService.getProductByBarcode(
      barcode,
    );
    return remoteResult.when(
      success: (product) async {
        // Cache to local Hive and sync to Firestore
        await saveFoodItem(product);
        return Result.success(product);
      },
      failure: (message, exception) {
        return Result.failure(message, exception);
      },
    );
  }

  /// AI Food Analysis using Gemini 1.5 Flash Vision
  Future<Result<NutritionAnalysisResult>> analyzeFoodImage({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    String? userNotes,
  }) async {
    final aiResult = await _geminiService.analyzeFoodImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      userNotes: userNotes,
    );

    return aiResult.when(
      success: (analysis) async {
        // Automatically create and persist FoodItem
        final foodItem = analysis.toFoodItem();
        await saveFoodItem(foodItem);
        return Result.success(analysis);
      },
      failure: (msg, ex) => Result.failure(msg, ex),
    );
  }

  @override
  Future<Result<List<FoodItem>>> getAllFoodItems() {
    return _localRepository.getAllFoodItems();
  }

  @override
  Future<Result<List<FoodItem>>> getRecentScans({int limit = 20}) {
    return _localRepository.getRecentScans(limit: limit);
  }

  @override
  Future<Result<void>> deleteFoodItem(String id) async {
    final localResult = await _localRepository.deleteFoodItem(id);
    if (cloudRepository != null) {
      cloudRepository!.deleteFoodItem(id).ignore();
    }
    return localResult;
  }

  @override
  Future<Result<void>> toggleFavorite(String id) async {
    final localResult = await _localRepository.toggleFavorite(id);
    if (cloudRepository != null) {
      cloudRepository!.toggleFavorite(id).ignore();
    }
    return localResult;
  }

  @override
  Future<Result<void>> clearAll() async {
    final local = await _localRepository.clearAll();
    if (cloudRepository != null) {
      cloudRepository!.clearAll().ignore();
    }
    return local;
  }

  /// Sync all local Hive items to Cloud Firestore
  Future<Result<int>> syncLocalToCloud() async {
    final cloud = cloudRepository;
    if (cloud is! FirestoreFoodRepository) {
      return Result.failure('Cloud Firestore ยังไม่ได้เชื่อมต่อ');
    }

    final localItemsResult = await _localRepository.getAllFoodItems();
    var items = localItemsResult.dataOrNull ?? [];

    // If local database is empty, seed initial sample meals into Hive first
    // so there is actual food data to sync up to Firestore!
    if (items.isEmpty) {
      final initialDemos = [
        FoodItem(
          id: 'demo_1',
          name: 'ข้าวกะเพราไก่ไข่ดาว',
          calories: 560,
          protein: 26,
          carbohydrates: 65,
          fat: 20,
          nutriScore: 'B',
          imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=150',
          scannedAt: DateTime.now(),
          source: 'ai_vision',
          isSynced: false,
        ),
        FoodItem(
          id: 'demo_2',
          name: 'ข้าวโอ๊ตออร์แกนิก เนเชอร์สพอยท์',
          calories: 190,
          protein: 6,
          carbohydrates: 32,
          fat: 4,
          nutriScore: 'A',
          imageUrl: 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=150',
          scannedAt: DateTime.now().subtract(const Duration(hours: 4)),
          source: 'barcode_scan',
          isSynced: false,
        ),
        FoodItem(
          id: 'demo_3',
          name: 'โยเกิร์ตกรีกพร้อมเบอร์รีรวม',
          calories: 180,
          protein: 12,
          carbohydrates: 20,
          fat: 5,
          nutriScore: 'A',
          imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=150',
          scannedAt: DateTime.now().subtract(const Duration(days: 1)),
          source: 'barcode_scan',
          isSynced: false,
        ),
        FoodItem(
          id: 'demo_4',
          name: 'ชามสลัดแซลมอนย่าง',
          calories: 520,
          protein: 34,
          carbohydrates: 28,
          fat: 22,
          nutriScore: 'A',
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=150',
          scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          source: 'ai_vision',
          isSynced: false,
        ),
      ];

      for (final demo in initialDemos) {
        await _localRepository.saveFoodItem(demo);
      }
      items = initialDemos;
    }

    final syncResult = await cloud.syncBatch(items);
    if (syncResult.isSuccess && _localRepository is HiveFoodRepository) {
      await _localRepository.markAsSynced(items.map((i) => i.id).toList());
    }
    return syncResult;
  }
}
