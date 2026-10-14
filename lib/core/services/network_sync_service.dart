import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nutrisnap/core/database/cloud/firestore_food_repository.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/features/nutrition/domain/repositories/food_repository.dart';

/// Network Connectivity Status & Cloud Firestore Auto-Sync Service.
/// Manages online/offline network detection and coordinates background/auto sync
/// from Hive Local Database to Cloud Firestore when internet connectivity is available.
class NetworkSyncService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _syncError;

  final FoodRepository? _localRepo;
  final FoodRepository? _cloudRepo;

  NetworkSyncService({
    this._localRepo,
    FoodRepository? cloudRepo,
    bool initialOnline = true,
  })  : _cloudRepo = cloudRepo,
        _isOnline = initialOnline;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get syncError => _syncError;

  /// Updates network connectivity status and triggers auto-sync if back online
  void updateConnectivityStatus(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    notifyListeners();

    if (_isOnline) {
      syncPendingItems();
    }
  }

  /// Explicitly sync pending offline Hive items to Cloud Firestore
  Future<bool> syncPendingItems() async {
    if (!_isOnline) {
      _syncError = 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      notifyListeners();
      return false;
    }

    if (_isSyncing) return false;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final local = _localRepo;
      final cloud = _cloudRepo;

      if (local is HiveFoodRepository && cloud is FirestoreFoodRepository) {
        final unsyncedResult = await local.getUnsyncedFoodItems();
        final unsynced = unsyncedResult.dataOrNull ?? [];

        if (unsynced.isNotEmpty) {
          final syncResult = await cloud.syncBatch(unsynced);
          if (syncResult.isSuccess) {
            final ids = unsynced.map((item) => item.id).toList();
            await local.markAsSynced(ids);
          }
        }
      } else if (local != null && cloud is FirestoreFoodRepository) {
        final allResult = await local.getAllFoodItems();
        if (allResult.isSuccess && allResult.dataOrNull != null) {
          await cloud.syncBatch(allResult.dataOrNull!);
        }
      }

      _lastSyncedAt = DateTime.now();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _syncError = 'เกิดข้อผิดพลาดในการซิงค์ข้อมูล: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}
