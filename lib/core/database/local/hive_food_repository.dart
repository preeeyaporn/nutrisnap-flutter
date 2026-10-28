import 'package:hive/hive.dart';
import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Local Database Repository using Hive with safe in-memory fallback for test environments.
class HiveFoodRepository implements FoodRepository {
  static bool isInitialized = false;
  final Box<Map>? _providedBox;
  Box<Map>? _activeBox;
  final Map<String, Map<String, dynamic>> _fallbackStore = {};

  HiveFoodRepository({Box<Map>? box}) : _providedBox = box;

  Future<Box<Map>?> _getBox() async {
    if (_providedBox != null) return _providedBox;
    if (!isInitialized) return null;
    if (_activeBox != null && _activeBox!.isOpen) return _activeBox;
    try {
      if (Hive.isBoxOpen(ApiConstants.foodBoxName)) {
        _activeBox = Hive.box<Map>(ApiConstants.foodBoxName);
      } else {
        _activeBox = await Hive.openBox<Map>(ApiConstants.foodBoxName);
      }
      return _activeBox;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async {
    try {
      final box = await _getBox();
      if (box != null) {
        await box.put(item.id, item.toMap());
      } else {
        _fallbackStore[item.id] = item.toMap();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ไม่สามารถบันทึกลง Hive Database: $e');
    }
  }

  @override
  Future<Result<FoodItem?>> getFoodItemById(String id) async {
    try {
      final box = await _getBox();
      final Map? data = box != null ? box.get(id) : _fallbackStore[id];
      if (data == null) return Result.success(null);
      final item = FoodItem.fromMap(Map<String, dynamic>.from(data));
      return Result.success(item);
    } catch (e) {
      return Result.failure('เกิดข้อผิดพลาดในการอ่านข้อมูล: $e');
    }
  }

  @override
  Future<Result<FoodItem?>> getFoodItemByBarcode(String barcode) async {
    try {
      final box = await _getBox();
      final values = box != null ? box.values : _fallbackStore.values;
      for (final value in values) {
        final map = Map<String, dynamic>.from(value);
        if (map['barcode'] == barcode) {
          return Result.success(FoodItem.fromMap(map));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ค้นหาบาร์โค้ดใน Hive ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<List<FoodItem>>> getAllFoodItems() async {
    try {
      final box = await _getBox();
      final values = box != null ? box.values : _fallbackStore.values;
      final items = values
          .map((v) => FoodItem.fromMap(Map<String, dynamic>.from(v)))
          .toList();
      items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return Result.success(items);
    } catch (e) {
      return Result.failure('ไม่สามารถดึงข้อมูลรายการอาหาร: $e');
    }
  }

  @override
  Future<Result<List<FoodItem>>> getRecentScans({int limit = 20}) async {
    final allResult = await getAllFoodItems();
    return allResult.when(
      success: (items) {
        final recent = items.take(limit).toList();
        return Result.success(recent);
      },
      failure: (msg, ex) => Result.failure(msg),
    );
  }

  @override
  Future<Result<void>> deleteFoodItem(String id) async {
    try {
      final box = await _getBox();
      if (box != null) {
        await box.delete(id);
      } else {
        _fallbackStore.remove(id);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ลบรายการไม่สำเร็จ: $e');
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String id) async {
    try {
      final box = await _getBox();
      final Map? data = box != null ? box.get(id) : _fallbackStore[id];
      if (data == null) {
        return Result.failure('ไม่พบรายการที่ต้องการบันทึกรายการโปรด');
      }
      final map = Map<String, dynamic>.from(data);
      final currentFav = map['isFavorite'] == true;
      map['isFavorite'] = !currentFav;
      if (box != null) {
        await box.put(id, map);
      } else {
        _fallbackStore[id] = map;
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('เกิดข้อผิดพลาดในการเปลี่ยนสถานะรายการโปรด: $e');
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      final box = await _getBox();
      if (box != null) {
        await box.clear();
      } else {
        _fallbackStore.clear();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ล้างข้อมูลล้มเหลว: $e');
    }
  }

  Future<Result<List<FoodItem>>> getUnsyncedFoodItems() async {
    try {
      final allResult = await getAllFoodItems();
      return allResult.when(
        success: (items) {
          final unsynced = items.where((item) => !item.isSynced).toList();
          return Result.success(unsynced);
        },
        failure: (msg, ex) => Result.failure(msg, ex),
      );
    } catch (e) {
      return Result.failure('ไม่สามารถดึงข้อมูลที่ยังไม่ได้ซิงค์: $e');
    }
  }

  Future<Result<void>> markAsSynced(List<String> ids) async {
    try {
      final box = await _getBox();
      for (final id in ids) {
        final Map? data = box != null ? box.get(id) : _fallbackStore[id];
        if (data != null) {
          final map = Map<String, dynamic>.from(data);
          map['isSynced'] = true;
          if (box != null) {
            await box.put(id, map);
          } else {
            _fallbackStore[id] = map;
          }
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('อัปเดตสถานะซิงค์ไม่สำเร็จ: $e');
    }
  }
}
