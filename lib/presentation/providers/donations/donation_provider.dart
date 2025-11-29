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

  void startUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      donationsStream = null;
      _donations = [];
      notifyListeners();
      return;
    }

    // Cargar donaciones locales primero (offline-first)
    _donations = _localStorage.getDonationsByUid(uid);
    notifyListeners();

    // Iniciar stream desde Firebase
    donationsStream = _streamUserDonations(uid);

    // Suscribirse al stream para cachear las donaciones
    _streamSubscription?.cancel();
    _streamSubscription = donationsStream!.listen((donations) {
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
      notifyListeners();
    });
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
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
      final input = DonationInput(
        description: description,
        type: type,
        size: size,
        brand: brand,
        tags: tags,
        localImagePath: localImagePath,
      );
      await _createDonation(uid: uid, input: input);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
