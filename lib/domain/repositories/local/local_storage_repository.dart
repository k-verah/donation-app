import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';

abstract class LocalStorageRepository {
  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  });
  Map<String, String> getFilterPreferences();
  Future<void> saveLastLocation(GeoPoint location);
  GeoPoint? getLastLocation();
  Future<void> cacheDonationPoints(List<FoundationPoint> points);
  List<FoundationPoint>? getCachedDonationPoints();
  bool isCacheValid();
  Future<void> clearCache();

  Future<void> saveDonation(Donation donation);
  Future<void> saveDonations(List<Donation> donations);
  List<Donation> getDonations();
  List<Donation> getDonationsByUid(String uid);
  List<Donation> getPendingDonations();
  Future<void> updateDonationSyncStatus(String id, SyncStatus status);
  bool isDonationsCacheValid();

  List<Donation> getAvailableDonations(String uid);
  List<Donation> getPendingCompletionDonations(String uid);
  List<Donation> getCompletedDonations(String uid);
  Future<void> updateDonationCompletionStatus(
      String id, DonationCompletionStatus status);
  Future<void> updateDonationsCompletionStatus(
      List<String> ids, DonationCompletionStatus status);

  Future<void> saveScheduleDonation(ScheduleDonation schedule);
  List<ScheduleDonation> getScheduleDonations();
  List<ScheduleDonation> getSchedulesByUid(String uid);
  List<ScheduleDonation> getPendingSchedules();
  Future<void> updateScheduleSyncStatus(String id, SyncStatus status);
  List<ScheduleDonation> getUndeliveredSchedules(String uid);
  List<ScheduleDonation> getDeliveredSchedules(String uid);
  Future<void> markScheduleAsDelivered(String id);

  Future<void> savePickupDonation(PickupDonation pickup);
  List<PickupDonation> getPickupDonations();
  List<PickupDonation> getPickupsByUid(String uid);
  List<PickupDonation> getPendingPickups();
  Future<void> updatePickupSyncStatus(String id, SyncStatus status);
  List<PickupDonation> getUndeliveredPickups(String uid);
  List<PickupDonation> getDeliveredPickups(String uid);
  Future<void> markPickupAsDelivered(String id);

  bool hasBookingForDate(String uid, DateTime date);

  Future<void> addToSyncQueue(SyncQueueItem item);
  List<SyncQueueItem> getSyncQueue();
  List<SyncQueueItem> getPendingSyncItems();
  Future<void> updateSyncQueueItem(SyncQueueItem item);
  Future<void> removeFromSyncQueue(String itemId);
  Future<void> clearSyncQueue();
  bool hasPendingSync();

  Future<void> clearAllLocalData();
}
