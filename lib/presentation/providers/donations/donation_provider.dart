import 'dart:async';
import 'package:donation_app/data/services/sync/connectivity_service.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'package:donation_app/domain/repositories/donations/donations_repository.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:donation_app/domain/use_cases/donations/create_donation.dart';
import 'package:donation_app/domain/use_cases/sensors/location/stream_user_donations.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class DonationProvider extends ChangeNotifier {
  final CreateDonation _createDonation;
  final StreamUserDonations _streamUserDonations;
  final LocalStorageRepository _localStorage;
  final DonationsRepository _donationsRepo;
  final ConnectivityService _connectivity;
  final FirebaseAuth _auth;

  DonationProvider({
    required CreateDonation createDonation,
    required StreamUserDonations streamUserDonations,
    required LocalStorageRepository localStorage,
    required DonationsRepository donationsRepo,
    required ConnectivityService connectivity,
    FirebaseAuth? auth,
  })  : _createDonation = createDonation,
        _streamUserDonations = streamUserDonations,
        _localStorage = localStorage,
        _donationsRepo = donationsRepo,
        _connectivity = connectivity,
        _auth = auth ?? FirebaseAuth.instance;

  bool _saving = false;
  bool get saving => _saving;

  Stream<List<Donation>>? donationsStream;
  StreamSubscription<List<Donation>>? _streamSubscription;

  /// Lista de donaciones cacheadas localmente
  List<Donation> _donations = [];
  List<Donation> get donations => List.unmodifiable(_donations);

  /// Donaciones disponibles para programar (no asignadas a pickup/schedule aún)
  List<Donation> get availableDonations {
    return _donations.where((d) => d.completionStatus.isAvailable).toList();
  }

  /// Donaciones pendientes de completar (asociadas a schedule/pickup)
  List<Donation> get pendingCompletionDonations {
    return _donations
        .where((d) => d.completionStatus.isPendingCompletion)
        .toList();
  }

  /// Donaciones completadas
  List<Donation> get completedDonations {
    return _donations.where((d) => d.completionStatus.isCompleted).toList();
  }

  /// Schedules no entregados
  List<ScheduleDonation> get undeliveredSchedules {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    return _localStorage.getUndeliveredSchedules(uid);
  }

  /// Pickups no entregados
  List<PickupDonation> get undeliveredPickups {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    return _localStorage.getUndeliveredPickups(uid);
  }

  StreamSubscription<bool>? _connectivitySubscription;
  String? _currentUid;

  void startUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      donationsStream = null;
      _donations = [];
      notifyListeners();
      return;
    }

    _currentUid = uid;

    // 1. SIEMPRE cargar donaciones locales primero (offline-first)
    _loadLocalDonations(uid);

    // 2. Si hay conexión, iniciar stream de Firebase
    if (_connectivity.isOnline) {
      _startFirebaseStream(uid);
    } else {
      debugPrint('📴 Offline: usando solo datos locales');
    }

    // 3. Escuchar cambios de conectividad para reconectar
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && _currentUid != null) {
        debugPrint('📶 Conexión restaurada: reconectando a Firebase...');
        _startFirebaseStream(_currentUid!);
      } else {
        debugPrint('📴 Sin conexión: usando caché local');
        _streamSubscription?.cancel();
      }
    });
  }

  void _loadLocalDonations(String uid) {
    _donations = _localStorage.getDonationsByUid(uid);
    debugPrint('💾 Cargadas ${_donations.length} donaciones del caché local');
    notifyListeners();
  }

  void _startFirebaseStream(String uid) {
    // Iniciar stream desde Firebase
    donationsStream = _streamUserDonations(uid);

    // Suscribirse al stream para cachear las donaciones
    _streamSubscription?.cancel();
    _streamSubscription = donationsStream!.listen(
      (donations) {
        // Preservar el completionStatus local al recibir datos de Firebase
        final localDonations = _localStorage.getDonationsByUid(uid);
        final mergedDonations = donations.map((d) {
          final local = localDonations.firstWhere(
            (l) => l.id == d.id,
            orElse: () => d,
          );
          // Si la donación local tiene un completionStatus diferente, preservarlo
          if (local.completionStatus != DonationCompletionStatus.available) {
            return d.copyWith(completionStatus: local.completionStatus);
          }
          return d;
        }).toList();

        _donations = mergedDonations;
        _localStorage.saveDonations(mergedDonations);
        debugPrint(
            '☁️ Sincronizadas ${mergedDonations.length} donaciones desde Firebase');
        notifyListeners();
      },
      onError: (error) {
        // Si hay error de conexión, usar datos locales
        debugPrint('⚠️ Error en stream de Firebase: $error');
        debugPrint('📴 Continuando con datos locales...');
        _loadLocalDonations(uid);
      },
    );
  }

  /// Obtiene una donación por ID
  Donation? getDonationById(String id) {
    try {
      return _donations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene múltiples donaciones por IDs
  List<Donation> getDonationsByIds(List<String> ids) {
    return _donations.where((d) => ids.contains(d.id)).toList();
  }

  /// Marca donaciones como pendientes de completar (cuando se asocian a schedule/pickup)
  Future<void> markDonationsAsPendingCompletion(
      List<String> donationIds) async {
    await _localStorage.updateDonationsCompletionStatus(
      donationIds,
      DonationCompletionStatus.pendingCompletion,
    );
    _refreshLocalDonations();
  }

  /// Completa un schedule y marca todas sus donaciones como completadas
  Future<void> completeScheduleDelivery(String scheduleId) async {
    final schedules = _localStorage.getScheduleDonations();
    final schedule = schedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found'),
    );

    // 1. Marcar donaciones como completadas (LOCAL)
    await _localStorage.updateDonationsCompletionStatus(
      schedule.donationIds,
      DonationCompletionStatus.completed,
    );

    // 2. Marcar schedule como entregado (LOCAL)
    await _localStorage.markScheduleAsDelivered(scheduleId);

    // 3. Encolar operaciones para sincronización
    // 3a. Encolar actualización de completionStatus de donaciones
    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsCompleted,
      entityId: scheduleId,
      payload: {'donationIds': schedule.donationIds},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(donationsSyncItem);

    // 3b. Encolar actualización del schedule como entregado
    final scheduleSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markScheduleDelivered,
      entityId: scheduleId,
      payload: {},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(scheduleSyncItem);

    // 4. Sincronizar a Firebase si hay conexión
    if (_connectivity.isOnline) {
      try {
        // Sincronizar donaciones
        await _donationsRepo.updateMultipleCompletionStatus(
          schedule.donationIds,
          DonationCompletionStatus.completed,
        );
        await _localStorage.removeFromSyncQueue(donationsSyncItem.id);

        // Sincronizar schedule (no hay método en repo, pero el SyncService lo manejará)
        await _localStorage.removeFromSyncQueue(scheduleSyncItem.id);

        debugPrint('✅ Synced schedule completion to Firebase');
      } catch (e) {
        debugPrint('⚠️ Failed to sync to Firebase, will retry later: $e');
        // Las operaciones quedan en la cola para sincronizar después
      }
    } else {
      debugPrint('📴 Offline - completion will sync when connection restored');
    }

    _refreshLocalDonations();
    debugPrint(
        '✅ Schedule $scheduleId completed with ${schedule.donationIds.length} donations');
  }

  /// Completa un pickup y marca todas sus donaciones como completadas
  Future<void> completePickupDelivery(String pickupId) async {
    final pickups = _localStorage.getPickupDonations();
    final pickup = pickups.firstWhere(
      (p) => p.id == pickupId,
      orElse: () => throw Exception('Pickup not found'),
    );

    // 1. Marcar donaciones como completadas (LOCAL)
    await _localStorage.updateDonationsCompletionStatus(
      pickup.donationIds,
      DonationCompletionStatus.completed,
    );

    // 2. Marcar pickup como entregado (LOCAL)
    await _localStorage.markPickupAsDelivered(pickupId);

    // 3. Encolar operaciones para sincronización
    // 3a. Encolar actualización de completionStatus de donaciones
    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsCompleted,
      entityId: pickupId,
      payload: {'donationIds': pickup.donationIds},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(donationsSyncItem);

    // 3b. Encolar actualización del pickup como entregado
    final pickupSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markPickupDelivered,
      entityId: pickupId,
      payload: {},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(pickupSyncItem);

    // 4. Sincronizar a Firebase si hay conexión
    if (_connectivity.isOnline) {
      try {
        // Sincronizar donaciones
        await _donationsRepo.updateMultipleCompletionStatus(
          pickup.donationIds,
          DonationCompletionStatus.completed,
        );
        await _localStorage.removeFromSyncQueue(donationsSyncItem.id);

        // Sincronizar pickup (no hay método en repo, pero el SyncService lo manejará)
        await _localStorage.removeFromSyncQueue(pickupSyncItem.id);

        debugPrint('✅ Synced pickup completion to Firebase');
      } catch (e) {
        debugPrint('⚠️ Failed to sync to Firebase, will retry later: $e');
        // Las operaciones quedan en la cola para sincronizar después
      }
    } else {
      debugPrint('📴 Offline - completion will sync when connection restored');
    }

    _refreshLocalDonations();
    debugPrint(
        '✅ Pickup $pickupId completed with ${pickup.donationIds.length} donations');
  }

  void _refreshLocalDonations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _donations = _localStorage.getDonationsByUid(uid);
    notifyListeners();
  }

  /// Revierte una donación completada a disponible
  Future<void> undoCompleteDonation(String donationId) async {
    // 1. Actualizar estado local
    await _localStorage.updateDonationCompletionStatus(
      donationId,
      DonationCompletionStatus.available,
    );

    // 2. Encolar para sincronización
    final syncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationAvailable,
      entityId: donationId,
      payload: {'donationId': donationId},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(syncItem);

    // 3. Sincronizar si hay conexión
    if (_connectivity.isOnline) {
      try {
        await _donationsRepo.updateCompletionStatus(
          donationId,
          DonationCompletionStatus.available,
        );
        await _localStorage.removeFromSyncQueue(syncItem.id);
        debugPrint('✅ Donation $donationId reverted to available');
      } catch (e) {
        debugPrint('⚠️ Failed to sync revert, will retry later: $e');
      }
    }

    _refreshLocalDonations();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Calcula racha (streak) con base en la lista recibida del stream
  int streakFrom(List<Donation> list) {
    if (list.isEmpty) return 0;
    final days = <DateTime>{};
    for (final d in list) {
      final local = d.createdAt.toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    // permitir racha si fue ayer
    if (streak == 0 &&
        days.contains(DateTime(now.year, now.month, now.day - 1))) {
      streak = 1;
      cursor = DateTime(
        now.year,
        now.month,
        now.day - 1,
      ).subtract(const Duration(days: 1));
      while (days.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  Future<void> create({
    required String description,
    required String type,
    required String size,
    required String brand,
    required List<String> tags,
    String? localImagePath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _saving = true;
    notifyListeners();

    try {
      // 1. Crear donación con ID local temporal
      final localId = 'local_${const Uuid().v4()}';
      final donation = Donation(
        id: localId,
        uid: uid,
        description: description,
        type: type,
        size: size,
        brand: brand,
        tags: tags,
        createdAt: DateTime.now(),
        localImagePath: localImagePath,
        completionStatus: DonationCompletionStatus.available,
      );

      // 2. Guardar localmente primero (offline-first)
      await _localStorage.saveDonation(donation);
      _donations = [donation, ..._donations];
      debugPrint('💾 Donación guardada localmente: $localId');
      notifyListeners();

      // 3. Intentar subir a Firebase si hay conexión
      if (_connectivity.isOnline) {
        try {
          final input = DonationInput(
            description: description,
            type: type,
            size: size,
            brand: brand,
            tags: tags,
            localImagePath: localImagePath,
          );
          await _createDonation(uid: uid, input: input);
          debugPrint('☁️ Donación sincronizada con Firebase');
        } catch (e) {
          // Si falla, encolar para sync posterior
          debugPrint('⚠️ Error subiendo a Firebase, encolando: $e');
          await _enqueueForSync(donation);
        }
      } else {
        // Sin conexión, encolar para sync
        debugPrint('📴 Sin conexión, encolando para sync posterior');
        await _enqueueForSync(donation);
      }
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _enqueueForSync(Donation donation) async {
    final syncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.createDonation,
      entityId: donation.id!,
      payload: {
        'uid': donation.uid,
        'description': donation.description,
        'type': donation.type,
        'size': donation.size,
        'brand': donation.brand,
        'tags': donation.tags,
        'localImagePath': donation.localImagePath,
      },
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(syncItem);
    debugPrint('📥 Donación encolada para sync: ${donation.id}');
  }
}
