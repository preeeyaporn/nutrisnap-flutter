import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:nutrisnap/core/constants/api_constants.dart';
import 'package:nutrisnap/core/utils/result.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Cloud Firestore Repository Implementation for NutriSnap.
/// Manages cloud sync, remote backup of food logs, and inaccurate data reports.
class FirestoreFoodRepository implements FoodRepository {
  String userId;
  String? userEmail;
  String? userDisplayName;
  double? userDailyTarget;
  final FirebaseFirestore? _customFirestore;
  final Map<String, Map<String, dynamic>> _cloudStore = {};
  final List<Map<String, dynamic>> _reportsStore = [];

  FirestoreFoodRepository({required this.userId, FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  void updateUserId(String newUserId) {
    if (newUserId.isNotEmpty) {
      userId = newUserId;
    }
  }

  void updateUserInfo({
    required String newUserId,
    String? email,
    String? displayName,
    double? dailyTarget,
  }) {
    if (newUserId.isNotEmpty) {
      userId = newUserId;
    }
    if (email != null && email.isNotEmpty) userEmail = email;
    if (displayName != null && displayName.isNotEmpty) userDisplayName = displayName;
    if (dailyTarget != null) userDailyTarget = dailyTarget;

    try {
      final uDoc = _userDoc;
      if (uDoc != null) {
        uDoc.set({
          'userId': userId,
          if (userEmail != null) 'email': userEmail,
          if (userDisplayName != null) 'displayName': userDisplayName,
          if (userDailyTarget != null) 'dailyCalorieTarget': userDailyTarget,
          'lastActiveAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)).ignore();
      }
    } catch (e) {
      debugPrint('Firestore updateUserInfo error: $e');
    }
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get firestoreInstance {
    if (_customFirestore != null) return _customFirestore;
    if (_isFirebaseAvailable) {
      try {
        return FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firestore instance notice: $e');
        return null;
      }
    }
    return null;
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final fs = firestoreInstance;
    if (fs == null) return null;
    return fs.collection(ApiConstants.firestoreUsersCollection).doc(userId);
  }

  CollectionReference<Map<String, dynamic>>? get _collection {
    return _userDoc?.collection(ApiConstants.firestoreFoodLogsCollection);
  }

  List<Map<String, dynamic>> get submittedReports =>
      List.unmodifiable(_reportsStore);

  @override
  Future<Result<void>> saveFoodItem(FoodItem item) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _cloudStore[item.id] = {
        ...item.toMap(),
        '_updatedAt': DateTime.now().toIso8601String(),
      };

      if (col != null) {
        await col.doc(item.id).set(data, SetOptions(merge: true));
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        _cloudStore[item.id] = data;
      }
      return Result.success(null);
    } catch (e) {
      debugPrint('Firestore saveFoodItem error: $e');
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
        return Result.success(null);
      }
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
      final col = _collection;
      if (col != null) {
        final doc = await col.doc(id).get();
        if (!doc.exists || doc.data() == null) return Result.failure('ไม่พบข้อมูลบน Firestore');
        final currentFav = doc.data()!['isFavorite'] == true;
        await col.doc(id).update({'isFavorite': !currentFav});
        return Result.success(null);
      } else {
        final item = _cloudStore[id];
        if (item == null) return Result.failure('ไม่พบข้อมูลบน Firestore');
        item['isFavorite'] = !(item['isFavorite'] == true);
        return Result.success(null);
      }
    } catch (e) {
      return Result.failure('อัปเดตสถานะบนคลาวด์ล้มเหลว: $e');
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      final col = _collection;
      final fs = firestoreInstance;
      if (col != null && fs != null) {
        final query = await col.get();
        final batch = fs.batch();
        for (final doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } else {
        _cloudStore.clear();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('ล้างข้อมูล Firestore ล้มเหลว: $e');
    }
  }

  /// Bulk syncs local items up to Cloud Firestore using Firestore Batch write
  Future<Result<int>> syncBatch(List<FoodItem> items) async {
    try {
      final col = _collection;
      final fs = firestoreInstance;
      final uDoc = _userDoc;

      if (uDoc != null) {
        await uDoc.set({
          'userId': userId,
          if (userEmail != null) 'email': userEmail,
          if (userDisplayName != null) 'displayName': userDisplayName,
          if (userDailyTarget != null) 'dailyCalorieTarget': userDailyTarget,
          'lastSyncAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      if (col != null && fs != null && items.isNotEmpty) {
        final batch = fs.batch();
        for (final item in items) {
          final docRef = col.doc(item.id);
          batch.set(
            docRef,
            {
              ...item.toMap(),
              '_updatedAt': DateTime.now().toIso8601String(),
            },
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        debugPrint('Firestore syncBatch: successfully wrote ${items.length} items to ${col.path}');
      } else {
        for (final item in items) {
          await saveFoodItem(item);
        }
      }
      return Result.success(items.length);
    } catch (e) {
      debugPrint('Firestore syncBatch error: $e');
      return Result.failure('ซิงค์ข้อมูลไปยัง Cloud ล้มเหลว: $e');
    }
  }
}
