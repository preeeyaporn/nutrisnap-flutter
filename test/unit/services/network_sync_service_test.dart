import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisnap/core/database/cloud/firestore_food_repository.dart';
import 'package:nutrisnap/core/database/local/hive_food_repository.dart';
import 'package:nutrisnap/core/services/network_sync_service.dart';
import 'package:nutrisnap/features/nutrition/domain/models/food_item.dart';

void main() {
  late HiveFoodRepository localRepo;
  late FirestoreFoodRepository cloudRepo;
  late NetworkSyncService syncService;

  setUp(() {
    localRepo = HiveFoodRepository();
    cloudRepo = FirestoreFoodRepository(userId: 'test_user');
    syncService = NetworkSyncService(
      localRepo: localRepo,
      cloudRepo: cloudRepo,
      initialOnline: true,
    );
  });

  group('NetworkSyncService Unit Tests', () {
    test('initial state reflects connectivity parameters', () {
      expect(syncService.isOnline, true);
      expect(syncService.isSyncing, false);
      expect(syncService.syncError, isNull);
    });

    test('updateConnectivityStatus updates state and notifies listeners', () {
      bool notified = false;
      syncService.addListener(() => notified = true);

      syncService.updateConnectivityStatus(false);
      expect(syncService.isOnline, false);
      expect(notified, true);
    });

    test('syncPendingItems syncs unsynced items from Hive to Firestore', () async {
      await localRepo.clearAll();
      await cloudRepo.clearAll();

      final offlineItem = FoodItem(
        id: 'offline_1',
        name: 'ข้าวผัดกะเพราออฟไลน์',
        calories: 550,
        protein: 24,
        carbohydrates: 60,
        fat: 18,
        scannedAt: DateTime.now(),
        isSynced: false,
      );

      await localRepo.saveFoodItem(offlineItem);

      final unsyncedBefore = await localRepo.getUnsyncedFoodItems();
      expect(unsyncedBefore.dataOrNull?.length, 1);

      final success = await syncService.syncPendingItems();
      expect(success, true);
      expect(syncService.lastSyncedAt, isNotNull);

      final unsyncedAfter = await localRepo.getUnsyncedFoodItems();
      expect(unsyncedAfter.dataOrNull?.length, 0);

      final cloudItem = await cloudRepo.getFoodItemById('offline_1');
      expect(cloudItem.dataOrNull?.name, 'ข้าวผัดกะเพราออฟไลน์');
    });

    test('syncPendingItems fails when offline', () async {
      syncService.updateConnectivityStatus(false);
      final success = await syncService.syncPendingItems();
      expect(success, false);
      expect(syncService.syncError, 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต');
    });
  });
}
