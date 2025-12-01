import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/datasources/analytics/analytics_donation_pickup_datasource.dart';
import 'package:donation_app/data/datasources/donations/booking_datasource.dart';
import 'package:donation_app/data/datasources/donations/donations_datasource.dart';
import 'package:donation_app/data/datasources/donations/pickup_donation_datasource.dart';
import 'package:donation_app/data/services/sync/connectivity_service.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'package:donation_app/domain/repositories/donations/pickup_donation_repository.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:uuid/uuid.dart';

class PickupDonationRepositoryImpl implements PickupDonationRepository {
  final FirebaseFirestore db;
  final BookingDatasource bookingDS;
  final PickupDonationDatasource pickupDS;
  final AnalyticsRemoteDatasource analyticsDS;
  final LocalStorageRepository localStorage;
  final ConnectivityService connectivity;
  final DonationsDataSource donationsDS;

  PickupDonationRepositoryImpl(
    this.db,
    this.bookingDS,
    this.pickupDS,
    this.analyticsDS, {
    required this.localStorage,
    required this.connectivity,
    required this.donationsDS,
  });

  @override
  Future<void> confirmPickup(PickupDonation p) async {
    if (localStorage.hasBookingForDate(p.uid, p.date)) {
      throw FirebaseException(
        plugin: 'local',
        message: 'You already have a donation scheduled for this date.',
      );
    }

    final pickupWithPending = p.copyWith(syncStatus: SyncStatus.pending);
    await localStorage.savePickupDonation(pickupWithPending);

    await localStorage.updateDonationsCompletionStatus(
      p.donationIds,
      DonationCompletionStatus.pendingCompletion,
    );

    final pickupSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.createPickup,
      entityId: p.id,
      payload: p.toJson(),
      createdAt: DateTime.now(),
    );
    await localStorage.addToSyncQueue(pickupSyncItem);

    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsPendingCompletion,
      entityId: p.id,
      payload: {'donationIds': p.donationIds},
      createdAt: DateTime.now(),
    );
    await localStorage.addToSyncQueue(donationsSyncItem);

    if (connectivity.isOnline) {
      try {
        await _syncToFirebase(p);
        await localStorage.updatePickupSyncStatus(p.id, SyncStatus.synced);
        await localStorage.removeFromSyncQueue(pickupSyncItem.id);

        await donationsDS.updateMultipleCompletionStatus(
          p.donationIds,
          DonationCompletionStatus.pendingCompletion,
        );
        await localStorage.removeFromSyncQueue(donationsSyncItem.id);
      } catch (e) {}
    } else {}
  }

  Future<void> _syncToFirebase(PickupDonation p) async {
    final docPickup = pickupDS.newDoc(p.id);
    final docDay = bookingDS.dayDoc(p.uid, p.date);
    final docAnalytics = analyticsDS.globalDoc();

    await db.runTransaction((tx) async {
      final daySnap = await tx.get(docDay);
      if (daySnap.exists) {
        final data = daySnap.data()!;
        final hasSchedule = (data['scheduleId'] ?? '') is String &&
            (data['scheduleId'] ?? '') != '';
        final hasPickup = (data['pickupId'] ?? '') is String &&
            (data['pickupId'] ?? '') != '';
        if (hasSchedule || hasPickup) {
          throw FirebaseException(
            plugin: 'firestore',
            message: 'You already have a donation scheduled for this date.',
          );
        }
      }

      tx.set(docPickup, pickupDS.toMap(p));

      tx.set(
        docDay,
        {
          'uid': p.uid,
          'dayKey': bookingDS.dayKey(p.date),
          'scheduleId': null,
          'pickupId': p.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(docAnalytics, analyticsDS.incPickup(), SetOptions(merge: true));
    });
  }

  @override
  List<PickupDonation> getPickupsByUid(String uid) {
    return localStorage.getPickupsByUid(uid);
  }

  @override
  List<PickupDonation> getPendingPickups() {
    return localStorage.getPendingPickups();
  }
}
