import 'package:nutrisnap/core/database/cloud/firestore_food_repository.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/core/services/gemini_service.dart';
import 'package:nutrisnap/core/services/open_food_facts_service.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/models/nutrition_analysis_result.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Unified Repository coordinating Local Hive DB, Cloud Firestore,
/// Open Food Facts API, and Gemini AI Vision.
class NutriSnapRepositoryImpl implements FoodRepository {
  final FoodRepository _localRepository;
  final FoodRepository? cloudRepository;
  final OpenFoodFactsService _openFoodFactsService;
  final GeminiService _geminiService;
  final List<Map<String, dynamic>> _localReportsLog = [];

  NutriSnapRepositoryImpl({
    FoodRepository? localRepository,
    this.cloudRepository,
    OpenFoodFactsService? openFoodFactsService,
    GeminiService? geminiService,
  }) : _localRepository = localRepository ?? HiveFoodRepository(),
       _openFoodFactsService =
           openFoodFactsService ?? OpenFoodFactsServiceImpl(),
       _geminiService = geminiService ?? GeminiServiceImpl();

  List<Map<String, dynamic>> get localReportsLog =>
      List.unmodifiable(_localReportsLog);

  GeminiService get geminiService => _geminiService;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  void updateUserId(String newUserId) {
    _currentUserId = newUserId;
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
    _currentUserId = newUserId;
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

  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async {
    final itemToSave = (_currentUserId != null && item.userId == null)
        ? item.copyWith(userId: _currentUserId)
        : item;

    // 1. Save to local database (Hive)
    final localResult = await _localRepository.saveFoodItem(itemToSave);
    if (localResult.isFailure) return localResult;

    // 2. Sync to Cloud Firestore if connected
    if (cloudRepository != null) {
      cloudRepository!.saveFoodItem(itemToSave).ignore();
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
  Future<Result<FoodItem?>> getFoodItemByBarcode(
    String barcode, {
    bool forceRefresh = false,
  }) async {
    // 1. ตรวจสอบข้อมูลใน Local Database ก่อน:
    // หากผู้ใช้เคยแก้ไขข้อมูลด้วยตนเอง (isUserEdited == true) และไม่ได้สั่ง forceRefresh
    // ให้คืนค่าที่ผู้ใช้แก้ไขไว้ทันที เพื่อไม่ให้ถูกเขียนทับอัตโนมัติ
    final cachedResult = await _localRepository.getFoodItemByBarcode(barcode);
    final cachedItem = cachedResult.dataOrNull;
    if (cachedItem != null) {
      // ตรวจสอบว่า cachedItem เป็นข้อมูล fallback ชั่วคราวหรือไม่
      // หากเป็น fallback (เช่น อาหารไม่ระบุชื่อ หรือค่า default 140 kcal ที่ไม่มีแบรนด์)
      // ให้ปล่อยให้ไป query Open Food Facts ต่อ เพื่อดึงข้อมูลจริงจากเครือข่าย
      final isGenericFallback = cachedItem.name.contains('อาหารไม่ระบุชื่อ') ||
          (cachedItem.calories == 140.0 &&
              cachedItem.protein == 2.0 &&
              cachedItem.fat == 7.0 &&
              cachedItem.brand.isEmpty);

      if (cachedItem.isUserEdited || (!forceRefresh && !isGenericFallback)) {
        return Result.success(cachedItem);
      }
    }

    // 2. ดึงข้อมูลล่าสุดจาก Open Food Facts Service / Verified GDA Catalog
    final remoteResult = await _openFoodFactsService.getProductByBarcode(
      barcode,
    );
    return remoteResult.when(
      success: (product) async {
        final mergedProduct = cachedItem != null
            ? product.copyWith(
                isFavorite: cachedItem.isFavorite,
                isReported: cachedItem.isReported,
                reportNote: cachedItem.reportNote,
              )
            : product;
        // อัปเดตข้อมูลล่าสุดลง Local Hive และซิงค์ขึ้น Firestore
        await saveFoodItem(mergedProduct);
        return Result.success(mergedProduct);
      },
      failure: (message, exception) async {
        // 3. หากดึงข้อมูลออนไลน์ไม่สำเร็จ จึงดึงจาก Local Hive Cache สำรอง
        if (cachedItem != null) {
          return Result.success(cachedItem);
        }
        return Result.failure(message, exception);
      },
    );
  }

  /// 1. ระบบอัปเดตและ Refresh ฐานข้อมูลอาหารทั้งหมด (Bulk / Dynamic Update)
  /// ดึงข้อมูลเวอร์ชันล่าสุดจาก Open Food Facts สำหรับทุกรายการใน Local Database
  /// โดยข้ามรายการที่ผู้ใช้แก้ไขเอง (isUserEdited == true) เว้นแต่จะตั้ง overwriteUserEdited = true
  Future<Result<int>> refreshAllFoodItems({
    bool overwriteUserEdited = false,
  }) async {
    final allResult = await _localRepository.getAllFoodItems();
    return allResult.when(
      success: (items) async {
        int updatedCount = 0;
        for (final item in items) {
          if (item.barcode.isEmpty) continue;
          if (item.isUserEdited && !overwriteUserEdited) {
            continue; // ป้องกันไม่ให้ข้อมูลที่ผู้ใช้แก้ไขถูกเขียนทับอัตโนมัติ
          }

          final freshRes = await _openFoodFactsService.getProductByBarcode(
            item.barcode,
          );
          if (freshRes.isSuccess && freshRes.dataOrNull != null) {
            final freshItem = freshRes.dataOrNull!.copyWith(
              id: item.id,
              isFavorite: item.isFavorite,
              isUserEdited: false,
              scannedAt: item.scannedAt,
            );
            await saveFoodItem(freshItem);
            updatedCount++;
          }
        }
        return Result.success(updatedCount);
      },
      failure: (msg, ex) => Result.failure(msg, ex),
    );
  }

  /// 2. ฟังก์ชันบันทึกการแก้ไขข้อมูลโภชนาการด้วยตนเอง (User Manual Override)
  /// ตั้งค่า isUserEdited = true ทันทีเพื่อป้องกันการเขียนทับเมื่อซิงค์รอบใหม่
  Future<Result<FoodItem>> updateFoodItemManualOverride(
    FoodItem editedItem,
  ) async {
    final overrideItem = editedItem.copyWith(
      isUserEdited: true,
      source: 'manual_override',
      scannedAt: DateTime.now(),
    );
    final saveRes = await saveFoodItem(overrideItem);
    if (saveRes.isFailure) {
      return Result.failure(
        saveRes.errorOrNull ?? 'บันทึกการแก้ไขข้อมูลไม่สำเร็จ',
      );
    }
    return Result.success(overrideItem);
  }

  /// 3. ระบบรายงานข้อมูลผิดพลาด (Report Inaccurate Data)
  /// บันทึก Flag รายการสินค้าที่ข้อมูลไม่ตรงกับบรรจุภัณฑ์จริง พร้อมแนบค่าที่ถูกต้องไปยัง Backend / Firebase
  Future<Result<FoodItem>> reportInaccurateFoodData({
    required FoodItem originalItem,
    FoodItem? correctedItem,
    required String reason,
  }) async {
    final targetItem = (correctedItem ?? originalItem).copyWith(
      isReported: true,
      reportNote: reason,
      isUserEdited: correctedItem != null ? true : originalItem.isUserEdited,
      scannedAt: DateTime.now(),
    );

    await saveFoodItem(targetItem);

    final reportPayload = <String, dynamic>{
      'barcode': originalItem.barcode,
      'foodId': originalItem.id,
      'name': originalItem.name,
      'reason': reason,
      'originalValues': originalItem.toMap(),
      if (correctedItem != null) 'correctedValues': correctedItem.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _localReportsLog.add(reportPayload);

    final cloud = cloudRepository;
    if (cloud is FirestoreFoodRepository) {
      await cloud.submitDataReport(reportPayload);
    }

    return Result.success(targetItem);
  }

  /// AI Food Analysis using Gemini 1.5 Flash Vision
  Future<Result<NutritionAnalysisResult>> analyzeFoodImage({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    String? userNotes,
    String? imagePath,
  }) async {
    final aiResult = await _geminiService.analyzeFoodImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      userNotes: userNotes,
    );

    return aiResult.when(
      success: (analysis) async {
        // Automatically create and persist FoodItem
        final foodItem = analysis.toFoodItem(imageUrl: imagePath);
        await saveFoodItem(foodItem);
        return Result.success(analysis);
      },
      failure: (msg, ex) => Result.failure(msg, ex),
    );
  }

  Future<List<FoodItem>> _syncVerifiedCatalogItems(List<FoodItem> items) async {
    final synced = <FoodItem>[];
    for (final item in items) {
      if (!item.isUserEdited && item.barcode.isNotEmpty) {
        final verified = OpenFoodFactsServiceImpl.getCatalogItemIfPresent(
          item.barcode,
        );
        if (verified != null &&
            (item.calories != verified.calories ||
                item.fat != verified.fat ||
                item.sugar != verified.sugar ||
                item.servingsPerContainer != verified.servingsPerContainer)) {
          final upgraded = verified.copyWith(
            id: item.id,
            isFavorite: item.isFavorite,
            isSynced: item.isSynced,
            scannedAt: item.scannedAt,
          );
          await _localRepository.saveFoodItem(upgraded);
          synced.add(upgraded);
          continue;
        }
      }
      synced.add(item);
    }
    return synced;
  }

  @override
  Future<Result<List<FoodItem>>> getAllFoodItems() async {
    final res = await _localRepository.getAllFoodItems();
    return res.when(
      success: (items) async {
        final realItems = <FoodItem>[];
        for (final item in items) {
          if (item.id.startsWith('demo_')) {
            await _localRepository.deleteFoodItem(item.id);
            if (cloudRepository != null) {
              cloudRepository!.deleteFoodItem(item.id).ignore();
            }
          } else if (_currentUserId != null) {
            if (item.userId == null) {
              // ลบรายการแคชเก่าที่ตกค้างจากการทดสอบก่อนหน้าออกจากเครื่องอัตโนมัติ
              await _localRepository.deleteFoodItem(item.id);
            } else if (item.userId == _currentUserId) {
              realItems.add(item);
            }
          } else {
            realItems.add(item);
          }
        }
        return Result.success(await _syncVerifiedCatalogItems(realItems));
      },
      failure: (msg, ex) => Result.failure(msg, ex),
    );
  }

  @override
  Future<Result<List<FoodItem>>> getRecentScans({int limit = 20}) async {
    final allRes = await getAllFoodItems();
    return allRes.when(
      success: (items) => Result.success(items.take(limit).toList()),
      failure: (msg, ex) => Result.failure(msg, ex),
    );
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
    final items = localItemsResult.dataOrNull ?? [];

    final realItems = <FoodItem>[];
    for (final item in items) {
      if (item.id.startsWith('demo_')) {
        await _localRepository.deleteFoodItem(item.id);
        cloud.deleteFoodItem(item.id).ignore();
      } else if (_currentUserId != null) {
        if (item.userId == null) {
          await _localRepository.deleteFoodItem(item.id);
        } else if (item.userId == _currentUserId) {
          realItems.add(item);
        }
      } else {
        realItems.add(item);
      }
    }

    if (realItems.isEmpty) {
      return const Result.success(0);
    }

    final syncResult = await cloud.syncBatch(realItems);
    if (syncResult.isSuccess && _localRepository is HiveFoodRepository) {
      await _localRepository.markAsSynced(realItems.map((i) => i.id).toList());
    }
    return syncResult;
  }
}
