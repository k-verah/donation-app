import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/data/datasources/analytics/analytics_donation_pickup_datasource.dart';
import 'package:donation_app/data/datasources/donations/booking_datasource.dart';
import 'package:donation_app/data/datasources/donations/donations_datasource.dart';
import 'package:donation_app/data/datasources/donations/schedule_donation_datasource.dart';
import 'package:donation_app/data/services/sync/connectivity_service.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'package:donation_app/domain/repositories/donations/schedule_donation_repository.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:uuid/uuid.dart';

class ScheduleDonationRepositoryImpl implements ScheduleDonationRepository {
  final FirebaseFirestore db;
  final BookingDatasource bookingDS;
  final ScheduleDonationDatasource donationDS;
  final AnalyticsRemoteDatasource analyticsDS;
  final LocalStorageRepository localStorage;
  final ConnectivityService connectivity;
  final DonationsDataSource donationsDS;

  ScheduleDonationRepositoryImpl(
    this.db,
    this.bookingDS,
    this.donationDS,
    this.analyticsDS, {
    required this.localStorage,
    required this.connectivity,
    required this.donationsDS,
  });

  @override
  Future<void> confirmSchedule(ScheduleDonation d) async {
    if (localStorage.hasBookingForDate(d.uid, d.date)) {
      throw FirebaseException(
        plugin: 'local',
        message: 'You already have a donation scheduled for this date.',
      );
    }

    final scheduleWithPending = d.copyWith(syncStatus: SyncStatus.pending);
    await localStorage.saveScheduleDonation(scheduleWithPending);

    await localStorage.updateDonationsCompletionStatus(
      d.donationIds,
      DonationCompletionStatus.pendingCompletion,
    );

    final scheduleSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.createSchedule,
      entityId: d.id,
      payload: d.toJson(),
      createdAt: DateTime.now(),
    );
    await localStorage.addToSyncQueue(scheduleSyncItem);

    final donationsSyncItem = SyncQueueItem(
      id: const Uuid().v4(),
      operation: SyncOperation.markDonationsPendingCompletion,
      entityId: d.id,
      payload: {'donationIds': d.donationIds},
      createdAt: DateTime.now(),
    );
    await localStorage.addToSyncQueue(donationsSyncItem);

    if (connectivity.isOnline) {
      try {
        await _syncToFirebase(d);
        await localStorage.updateScheduleSyncStatus(d.id, SyncStatus.synced);
        await localStorage.removeFromSyncQueue(scheduleSyncItem.id);

        await donationsDS.updateMultipleCompletionStatus(
          d.donationIds,
          DonationCompletionStatus.pendingCompletion,
        );
        await localStorage.removeFromSyncQueue(donationsSyncItem.id);
      } catch (e) {}
    } else {}
  }

  Future<void> _syncToFirebase(ScheduleDonation d) async {
    final docDonation = donationDS.newDoc(d.id);
    final docDay = bookingDS.dayDoc(d.uid, d.date);
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

      tx.set(docDonation, donationDS.toMap(d));

      tx.set(
        docDay,
        {
          'uid': d.uid,
          'dayKey': bookingDS.dayKey(d.date),
          'scheduleId': d.id,
          'pickupId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(docAnalytics, analyticsDS.incSchedule(), SetOptions(merge: true));
    });
  }

  @override
  List<ScheduleDonation> getSchedulesByUid(String uid) {
    return localStorage.getSchedulesByUid(uid);
  }

  @override
  List<ScheduleDonation> getPendingSchedules() {
    return localStorage.getPendingSchedules();
  }
}
