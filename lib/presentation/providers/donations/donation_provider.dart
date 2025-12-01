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

  List<Donation> _donations = [];
  List<Donation> get donations => List.unmodifiable(_donations);

  List<Donation> get availableDonations {
    return _donations.where((d) => d.completionStatus.isAvailable).toList();
  }

  List<Donation> get pendingCompletionDonations {
    return _donations
        .where((d) => d.completionStatus.isPendingCompletion)
        .toList();
  }

  List<Donation> get completedDonations {
    return _donations.where((d) => d.completionStatus.isCompleted).toList();
  }

  List<ScheduleDonation> get undeliveredSchedules {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    return _localStorage.getUndeliveredSchedules(uid);
  }

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

    _loadLocalDonations(uid);

    if (_connectivity.isOnline) {
      _startFirebaseStream(uid);
    } else {}

    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && _currentUid != null) {
        _startFirebaseStream(_currentUid!);
      } else {
        _streamSubscription?.cancel();
      }
    });
  }

  void _loadLocalDonations(String uid) {
    _donations = _localStorage.getDonationsByUid(uid);
    notifyListeners();
  }

  void _startFirebaseStream(String uid) {
    donationsStream = _streamUserDonations(uid);

    _streamSubscription?.cancel();
    _streamSubscription = donationsStream!.listen(
      (donations) {
        final localDonations = _localStorage.getDonationsByUid(uid);
        final mergedDonations = donations.map((d) {
          final local = localDonations.firstWhere(
            (l) => l.id == d.id,
            orElse: () => d,
          );

          if (local.completionStatus != DonationCompletionStatus.available) {
            return d.copyWith(completionStatus: local.completionStatus);
          }
          return d;
        }).toList();

        _donations = mergedDonations;
        _localStorage.saveDonations(mergedDonations);
        notifyListeners();
      },
      onError: (error) {
        _loadLocalDonations(uid);
      },
    );
  }

  Donation? getDonationById(String id) {
    try {
      return _donations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Donation> getDonationsByIds(List<String> ids) {
    return _donations.where((d) => ids.contains(d.id)).toList();
  }

  Future<void> markDonationsAsPendingCompletion(
      List<String> donationIds) async {
    await _localStorage.updateDonationsCompletionStatus(
      donationIds,
      DonationCompletionStatus.pendingCompletion,
    );
    _refreshLocalDonations();
  }

  Future<void> completeScheduleDelivery(String scheduleId) async {
    final schedules = _localStorage.getScheduleDonations();
    final schedule = schedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found'),
    );

    await _localStorage.updateDonationsCompletionStatus(
      schedule.donationIds,
      DonationCompletionStatus.completed,
    );

    await _localStorage.markScheduleAsDelivered(scheduleId);

    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsCompleted,
      entityId: scheduleId,
      payload: {'donationIds': schedule.donationIds},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(donationsSyncItem);

    final scheduleSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markScheduleDelivered,
      entityId: scheduleId,
      payload: {},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(scheduleSyncItem);

    if (_connectivity.isOnline) {
      try {
        await _donationsRepo.updateMultipleCompletionStatus(
          schedule.donationIds,
          DonationCompletionStatus.completed,
        );
        await _localStorage.removeFromSyncQueue(donationsSyncItem.id);

        await _localStorage.removeFromSyncQueue(scheduleSyncItem.id);
      } catch (e) {}
    }

    _refreshLocalDonations();
  }

  Future<void> completePickupDelivery(String pickupId) async {
    final pickups = _localStorage.getPickupDonations();
    final pickup = pickups.firstWhere(
      (p) => p.id == pickupId,
      orElse: () => throw Exception('Pickup not found'),
    );

    await _localStorage.updateDonationsCompletionStatus(
      pickup.donationIds,
      DonationCompletionStatus.completed,
    );

    await _localStorage.markPickupAsDelivered(pickupId);

    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsCompleted,
      entityId: pickupId,
      payload: {'donationIds': pickup.donationIds},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(donationsSyncItem);

    final pickupSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markPickupDelivered,
      entityId: pickupId,
      payload: {},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(pickupSyncItem);

    if (_connectivity.isOnline) {
      try {
        await _donationsRepo.updateMultipleCompletionStatus(
          pickup.donationIds,
          DonationCompletionStatus.completed,
        );
        await _localStorage.removeFromSyncQueue(donationsSyncItem.id);

        await _localStorage.removeFromSyncQueue(pickupSyncItem.id);
      } catch (e) {}
    }

    _refreshLocalDonations();
  }

  void _refreshLocalDonations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _donations = _localStorage.getDonationsByUid(uid);
    notifyListeners();
  }

  Future<void> undoCompleteDonation(String donationId) async {
    await _localStorage.updateDonationCompletionStatus(
      donationId,
      DonationCompletionStatus.available,
    );

    final syncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationAvailable,
      entityId: donationId,
      payload: {'donationId': donationId},
      createdAt: DateTime.now(),
    );
    await _localStorage.addToSyncQueue(syncItem);

    if (_connectivity.isOnline) {
      try {
        await _donationsRepo.updateCompletionStatus(
          donationId,
          DonationCompletionStatus.available,
        );
        await _localStorage.removeFromSyncQueue(syncItem.id);
      } catch (e) {}
    }

    _refreshLocalDonations();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

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

      await _localStorage.saveDonation(donation);
      _donations = [donation, ..._donations];

      notifyListeners();

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
        } catch (e) {
          await _enqueueForSync(donation);
        }
      } else {
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
  }
}
