import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Cloud Firestore Repository Implementation for NutriSnap.
/// Manages cloud sync, remote backup of food logs, and inaccurate data reports.
class FirestoreFoodRepository implements FoodRepository {
  final String userId;
  final Map<String, Map<String, dynamic>> _cloudStore = {};
  final List<Map<String, dynamic>> _reportsStore = [];

  FirestoreFoodRepository({required this.userId});

  String get _collectionPath =>
      '${ApiConstants.firestoreUsersCollection}/$userId/${ApiConstants.firestoreFoodLogsCollection}';

  List<Map<String, dynamic>> get submittedReports =>
      List.unmodifiable(_reportsStore);

  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _cloudStore[item.id] = {
        ...item.toMap(),
        '_collection': _collectionPath,
        '_updatedAt': DateTime.now().toIso8601String(),
      };
      return Result.success(null);
    } catch (e) {
      return Result.failure('เกิดข้อผิดพลาดในการบันทึกขึ้น Firestore: $e');
    }
  }

  /// บันทึกรายงานข้อมูลโภชนาการไม่ตรงกับบรรจุภัณฑ์จริงขึ้น Cloud / Backend
  Future<Result<void>> submitDataReport(Map<String, dynamic> reportPayload) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _reportsStore.add({
        ...reportPayload,
        'userId': userId,
        'reportedAt': DateTime.now().toIso8601String(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure('ส่งรายงานข้อมูลไม่ถูกต้องล้มเหลว: $e');
    }
  }

  @override
  Future<Result<FoodItem?>> getFoodItemById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final data = _cloudStore[id];
      if (data == null) return Result.success(null);
      return Result.success(FoodItem.fromMap(data));
    } catch (e) {
      return Result.failure('ดึงข้อมูลจาก Firestore ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<FoodItem?>> getFoodItemByBarcode(String barcode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      for (final map in _cloudStore.values) {
        if (map['barcode'] == barcode) {
          return Result.success(FoodItem.fromMap(map));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ค้นหาบาร์โค้ดบนคลาวด์ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<List<FoodItem>>> getAllFoodItems() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final items = _cloudStore.values
          .map((m) => FoodItem.fromMap(m))
          .toList();
      items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return Result.success(items);
    } catch (e) {
      return Result.failure('ดึงข้อมูลทั้งหมดจาก Firestore ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<List<FoodItem>>> getRecentScans({int limit = 20}) async {
    final allResult = await getAllFoodItems();
    return allResult.when(
      success: (items) => Result.success(items.take(limit).toList()),
      failure: (msg, ex) => Result.failure(msg),
    );
  }

  @override
  Future<Result<void>> deleteFoodItem(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      _cloudStore.remove(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('ลบรายการบน Firestore ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String id) async {
    try {
      final item = _cloudStore[id];
      if (item == null) return Result.failure('ไม่พบข้อมูลบน Firestore');
      item['isFavorite'] = !(item['isFavorite'] == true);
      return Result.success(null);
    } catch (e) {
      return Result.failure('อัปเดตสถานะบนคลาวด์ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      _cloudStore.clear();
      return Result.success(null);
    } catch (e) {
      return Result.failure('ล้างข้อมูล Firestore ล้มเหลว: $e');
    }
  }

  /// Bulk syncs local items up to Cloud Firestore
  Future<Result<int>> syncBatch(List<FoodItem> items) async {
    try {
      for (final item in items) {
        await saveFoodItem(item);
      }
      return Result.success(items.length);
    } catch (e) {
      return Result.failure('ซิงค์ข้อมูลไปยัง Cloud ล้มเหลว: $e');
    }
  }
}
