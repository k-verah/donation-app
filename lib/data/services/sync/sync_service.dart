import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/services/sync/connectivity_service.dart';
import 'package:donation_app/data/services/sync/background_sync.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:donation_app/data/datasources/donations/donations_datasource.dart';
import 'package:donation_app/data/datasources/donations/schedule_donation_datasource.dart';
import 'package:donation_app/data/datasources/donations/pickup_donation_datasource.dart';
import 'package:donation_app/data/datasources/donations/booking_datasource.dart';

/// Servicio de sincronización offline-first
///
/// Maneja la cola de operaciones pendientes y las sincroniza
/// cuando hay conexión disponible.
///
/// Usa Isolates para operaciones pesadas evitando bloquear la UI.
class SyncService with BackgroundProcessingMixin {
  final ConnectivityService _connectivity;
  final LocalStorageRepository _localStorage;
  final FirebaseFirestore _firestore;
  final DonationsDataSource _donationsDS;
  final ScheduleDonationDatasource _scheduleDS;
  final PickupDonationDatasource _pickupDS;
  final BookingDatasource _bookingDS;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncServiceStatus>.broadcast();
  Stream<SyncServiceStatus> get syncStatus => _syncStatusController.stream;

  SyncService({
    required ConnectivityService connectivity,
    required LocalStorageRepository localStorage,
    required FirebaseFirestore firestore,
    required DonationsDataSource donationsDS,
    required ScheduleDonationDatasource scheduleDS,
    required PickupDonationDatasource pickupDS,
    required BookingDatasource bookingDS,
  })  : _connectivity = connectivity,
        _localStorage = localStorage,
        _firestore = firestore,
        _donationsDS = donationsDS,
        _scheduleDS = scheduleDS,
        _pickupDS = pickupDS,
        _bookingDS = bookingDS;

  /// Inicializa el servicio y comienza a escuchar cambios de conectividad
  void init() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('🔄 Connection restored, starting sync...');
        syncPendingOperations();
      }
    });

    // Intentar sincronizar al iniciar si hay conexión
    if (_connectivity.isOnline) {
      syncPendingOperations();
    }
  }

  /// Sincroniza todas las operaciones pendientes
  ///
  /// Usa background processing para operaciones pesadas
  Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress, skipping...');
      return;
    }

    if (!_connectivity.isOnline) {
      debugPrint('📴 No connection, skipping sync');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncServiceStatus.syncing);

    try {
      final pendingItems = _localStorage.getPendingSyncItems();
      debugPrint('📤 Found ${pendingItems.length} pending items to sync');

      // Para listas grandes, preparar datos en background
      List<SyncQueueItem> itemsToProcess = pendingItems;
      if (shouldUseIsolate(pendingItems.length)) {
        debugPrint(
            '🔄 Processing ${pendingItems.length} items in background...');
        final jsonItems = pendingItems.map((e) => e.toJson()).toList();
        final processedJson = await prepareDataForSync(jsonItems);
        itemsToProcess =
            processedJson.map((json) => SyncQueueItem.fromJson(json)).toList();
      }

      int successCount = 0;
      int failCount = 0;

      for (final item in itemsToProcess) {
        try {
          await _processSyncItem(item);
          await _localStorage.removeFromSyncQueue(item.id);
          successCount++;
        } catch (e) {
          debugPrint('❌ Failed to sync item ${item.id}: $e');
          failCount++;

          // Actualizar intentos
          final updated = item.copyWith(
            attempts: item.attempts + 1,
            lastAttempt: DateTime.now(),
            lastError: e.toString(),
          );
          await _localStorage.updateSyncQueueItem(updated);

          // Si excedió los reintentos, marcar la entidad como fallida
          if (!updated.canRetry) {
            await _markEntityAsFailed(item);
          }
        }
      }

      debugPrint('✅ Sync completed: $successCount success, $failCount failed');

      _syncStatusController.add(
        failCount > 0
            ? SyncServiceStatus.partialSuccess
            : SyncServiceStatus.idle,
      );
    } catch (e) {
      debugPrint('💥 Sync error: $e');
      _syncStatusController.add(SyncServiceStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncItem(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.createSchedule:
        await _syncScheduleDonation(item);
        break;
      case SyncOperation.createPickup:
        await _syncPickupDonation(item);
        break;
      case SyncOperation.createDonation:
        await _syncDonation(item);
        break;
      case SyncOperation.markDonationsPendingCompletion:
        await _syncDonationsCompletionStatus(
            item, DonationCompletionStatus.pendingCompletion);
        break;
      case SyncOperation.markDonationsCompleted:
        await _syncDonationsCompletionStatus(
            item, DonationCompletionStatus.completed);
        break;
      case SyncOperation.markScheduleDelivered:
        await _syncScheduleDelivered(item);
        break;
      case SyncOperation.markPickupDelivered:
        await _syncPickupDelivered(item);
        break;
      case SyncOperation.markDonationAvailable:
        await _syncDonationAvailable(item);
        break;
      default:
        debugPrint('⚠️ Unknown operation: ${item.operation}');
    }
  }

  Future<void> _syncScheduleDonation(SyncQueueItem item) async {
    final schedules = _localStorage.getScheduleDonations();
    final schedule = schedules.firstWhere(
      (s) => s.id == item.entityId,
      orElse: () => throw Exception('Schedule not found locally'),
    );

    final docDonation = _scheduleDS.newDoc(schedule.id);
    final docDay = _bookingDS.dayDoc(schedule.uid, schedule.date);

    await _firestore.runTransaction((tx) async {
      // Verificar que no haya conflicto
      final daySnap = await tx.get(docDay);
      if (daySnap.exists) {
        final data = daySnap.data()!;
        final hasSchedule = (data['scheduleId'] ?? '') != '';
        final hasPickup = (data['pickupId'] ?? '') != '';
        if (hasSchedule || hasPickup) {
          throw Exception('Conflict: already have a donation for this day');
        }
      }

      tx.set(docDonation, _scheduleDS.toMap(schedule));
      tx.set(
        docDay,
        {
          'uid': schedule.uid,
          'dayKey': _bookingDS.dayKey(schedule.date),
          'scheduleId': schedule.id,
          'pickupId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    // Marcar como sincronizado
    await _localStorage.updateScheduleSyncStatus(
        schedule.id, SyncStatus.synced);
    debugPrint('✅ Schedule ${schedule.id} synced successfully');
  }

  Future<void> _syncPickupDonation(SyncQueueItem item) async {
    final pickups = _localStorage.getPickupDonations();
    final pickup = pickups.firstWhere(
      (p) => p.id == item.entityId,
      orElse: () => throw Exception('Pickup not found locally'),
    );

    final docDonation = _pickupDS.newDoc(pickup.id);
    final docDay = _bookingDS.dayDoc(pickup.uid, pickup.date);

    await _firestore.runTransaction((tx) async {
      final daySnap = await tx.get(docDay);
      if (daySnap.exists) {
        final data = daySnap.data()!;
        final hasSchedule = (data['scheduleId'] ?? '') != '';
        final hasPickup = (data['pickupId'] ?? '') != '';
        if (hasSchedule || hasPickup) {
          throw Exception('Conflict: already have a donation for this day');
        }
      }

      tx.set(docDonation, _pickupDS.toMap(pickup));
      tx.set(
        docDay,
        {
          'uid': pickup.uid,
          'dayKey': _bookingDS.dayKey(pickup.date),
          'scheduleId': null,
          'pickupId': pickup.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await _localStorage.updatePickupSyncStatus(pickup.id, SyncStatus.synced);
    debugPrint('✅ Pickup ${pickup.id} synced successfully');
  }

  Future<void> _syncDonation(SyncQueueItem item) async {
    // Para donaciones individuales (si las creas offline)
    final donations = _localStorage.getDonations();
    final donation = donations.firstWhere(
      (d) => d.id == item.entityId,
      orElse: () => throw Exception('Donation not found locally'),
    );

    await _firestore.collection('donations').doc(donation.id).set({
      'uid': donation.uid,
      'description': donation.description,
      'type': donation.type,
      'size': donation.size,
      'brand': donation.brand,
      'tags': donation.tags,
      'createdAt': Timestamp.fromDate(donation.createdAt),
      'localImagePath': donation.localImagePath,
      'completionStatus': donation.completionStatus.toJson(),
    });

    await _localStorage.updateDonationSyncStatus(
        donation.id!, SyncStatus.synced);
    debugPrint('✅ Donation ${donation.id} synced successfully');
  }

  /// Sincroniza el cambio de completionStatus de múltiples donaciones
  Future<void> _syncDonationsCompletionStatus(
    SyncQueueItem item,
    DonationCompletionStatus status,
  ) async {
    final donationIds = List<String>.from(item.payload['donationIds'] as List);

    await _donationsDS.updateMultipleCompletionStatus(donationIds, status);

    debugPrint(
        '✅ Updated ${donationIds.length} donations to ${status.name} in Firebase');
  }

  /// Sincroniza que un schedule fue marcado como entregado
  Future<void> _syncScheduleDelivered(SyncQueueItem item) async {
    final scheduleId = item.entityId;

    await _firestore.collection('schedule_donations').doc(scheduleId).update({
      'isDelivered': true,
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Schedule $scheduleId marked as delivered in Firebase');
  }

  /// Sincroniza que un pickup fue marcado como entregado
  Future<void> _syncPickupDelivered(SyncQueueItem item) async {
    final pickupId = item.entityId;

    await _firestore.collection('pickups').doc(pickupId).update({
      'isDelivered': true,
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Pickup $pickupId marked as delivered in Firebase');
  }

  /// Sincroniza que una donación fue revertida a disponible
  Future<void> _syncDonationAvailable(SyncQueueItem item) async {
    final donationId = item.entityId;

    await _donationsDS.updateCompletionStatus(
      donationId,
      DonationCompletionStatus.available,
    );

    debugPrint('✅ Donation $donationId reverted to available in Firebase');
  }

  Future<void> _markEntityAsFailed(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.createSchedule:
        await _localStorage.updateScheduleSyncStatus(
            item.entityId, SyncStatus.failed);
        break;
      case SyncOperation.createPickup:
        await _localStorage.updatePickupSyncStatus(
            item.entityId, SyncStatus.failed);
        break;
      case SyncOperation.createDonation:
        await _localStorage.updateDonationSyncStatus(
            item.entityId, SyncStatus.failed);
        break;
      default:
        // Para operaciones de update no hay entidad específica que marcar
        break;
    }
  }

  /// Verifica si hay operaciones pendientes
  bool get hasPendingSync => _localStorage.hasPendingSync();

  /// Cantidad de operaciones pendientes
  int get pendingCount => _localStorage.getPendingSyncItems().length;

  void dispose() {
    _connectivitySub?.cancel();
    _syncStatusController.close();
  }
}

enum SyncServiceStatus {
  idle,
  syncing,
  partialSuccess,
  error,
}
