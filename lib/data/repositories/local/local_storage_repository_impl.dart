import 'package:donation_app/data/datasources/local/local_storage_datasource.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';

class LocalStorageRepositoryImpl implements LocalStorageRepository {
  final LocalStorageDataSource dataSource;

  LocalStorageRepositoryImpl(this.dataSource);

  @override
  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    await dataSource.saveFilterPreferences(
      cause: cause,
      access: access,
      schedule: schedule,
    );
  }

  @override
  Map<String, String> getFilterPreferences() {
    return dataSource.getFilterPreferences();
  }

  @override
  Future<void> saveLastLocation(GeoPoint location) async {
    await dataSource.saveLastLocation(location);
  }

  @override
  GeoPoint? getLastLocation() {
    return dataSource.getLastLocation();
  }

  @override
  Future<void> cacheDonationPoints(List<FoundationPoint> points) async {
    await dataSource.cacheDonationPoints(points);
  }

  @override
  List<FoundationPoint>? getCachedDonationPoints() {
    return dataSource.getCachedDonationPoints();
  }

  @override
  bool isCacheValid() {
    return dataSource.isCacheValid();
  }

  @override
  Future<void> clearCache() async {
    await dataSource.clearCache();
  }

  @override
  Future<void> saveDonation(Donation donation) async {
    await dataSource.saveDonation(donation);
  }

  @override
  Future<void> saveDonations(List<Donation> donations) async {
    await dataSource.saveDonations(donations);
  }

  @override
  List<Donation> getDonations() {
    return dataSource.getDonations();
  }

  @override
  List<Donation> getDonationsByUid(String uid) {
    return dataSource.getDonationsByUid(uid);
  }

  @override
  List<Donation> getPendingDonations() {
    return dataSource.getPendingDonations();
  }

  @override
  Future<void> updateDonationSyncStatus(String id, SyncStatus status) async {
    await dataSource.updateDonationSyncStatus(id, status);
  }

  @override
  bool isDonationsCacheValid() {
    return dataSource.isDonationsCacheValid();
  }

  @override
  List<Donation> getAvailableDonations(String uid) {
    return dataSource.getAvailableDonations(uid);
  }

  @override
  List<Donation> getPendingCompletionDonations(String uid) {
    return dataSource.getPendingCompletionDonations(uid);
  }

  @override
  List<Donation> getCompletedDonations(String uid) {
    return dataSource.getCompletedDonations(uid);
  }

  @override
  Future<void> updateDonationCompletionStatus(
    String id,
    DonationCompletionStatus status,
  ) async {
    await dataSource.updateDonationCompletionStatus(id, status);
  }

  @override
  Future<void> updateDonationsCompletionStatus(
    List<String> ids,
    DonationCompletionStatus status,
  ) async {
    await dataSource.updateDonationsCompletionStatus(ids, status);
  }

  @override
  Future<void> saveScheduleDonation(ScheduleDonation schedule) async {
    await dataSource.saveScheduleDonation(schedule);
  }

  @override
  List<ScheduleDonation> getScheduleDonations() {
    return dataSource.getScheduleDonations();
  }

  @override
  List<ScheduleDonation> getSchedulesByUid(String uid) {
    return dataSource.getSchedulesByUid(uid);
  }

  @override
  List<ScheduleDonation> getPendingSchedules() {
    return dataSource.getPendingSchedules();
  }

  @override
  Future<void> updateScheduleSyncStatus(String id, SyncStatus status) async {
    await dataSource.updateScheduleSyncStatus(id, status);
  }

  @override
  List<ScheduleDonation> getUndeliveredSchedules(String uid) {
    return dataSource.getUndeliveredSchedules(uid);
  }

  @override
  List<ScheduleDonation> getDeliveredSchedules(String uid) {
    return dataSource.getDeliveredSchedules(uid);
  }

  @override
  Future<void> markScheduleAsDelivered(String id) async {
    await dataSource.markScheduleAsDelivered(id);
  }

  @override
  Future<void> savePickupDonation(PickupDonation pickup) async {
    await dataSource.savePickupDonation(pickup);
  }

  @override
  List<PickupDonation> getPickupDonations() {
    return dataSource.getPickupDonations();
  }

  @override
  List<PickupDonation> getPickupsByUid(String uid) {
    return dataSource.getPickupsByUid(uid);
  }

  @override
  List<PickupDonation> getPendingPickups() {
    return dataSource.getPendingPickups();
  }

  @override
  Future<void> updatePickupSyncStatus(String id, SyncStatus status) async {
    await dataSource.updatePickupSyncStatus(id, status);
  }

  @override
  List<PickupDonation> getUndeliveredPickups(String uid) {
    return dataSource.getUndeliveredPickups(uid);
  }

  @override
  List<PickupDonation> getDeliveredPickups(String uid) {
    return dataSource.getDeliveredPickups(uid);
  }

  @override
  Future<void> markPickupAsDelivered(String id) async {
    await dataSource.markPickupAsDelivered(id);
  }

  @override
  bool hasBookingForDate(String uid, DateTime date) {
    return dataSource.hasBookingForDate(uid, date);
  }

  @override
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    await dataSource.addToSyncQueue(item);
  }

  @override
  List<SyncQueueItem> getSyncQueue() {
    return dataSource.getSyncQueue();
  }

  @override
  List<SyncQueueItem> getPendingSyncItems() {
    return dataSource.getPendingSyncItems();
  }

  @override
  Future<void> updateSyncQueueItem(SyncQueueItem item) async {
    await dataSource.updateSyncQueueItem(item);
  }

  @override
  Future<void> removeFromSyncQueue(String itemId) async {
    await dataSource.removeFromSyncQueue(itemId);
  }

  @override
  Future<void> clearSyncQueue() async {
    await dataSource.clearSyncQueue();
  }

  @override
  bool hasPendingSync() {
    return dataSource.hasPendingSync();
  }

  @override
  Future<void> clearAllLocalData() async {
    await dataSource.clearAllLocalData();
  }

  @override
  Future<void> cacheDonationInsights(List<FoundationInsight> insights) async {
    await dataSource.cacheDonationInsights(insights);
  }

  @override
  List<FoundationInsight>? getCachedDonationInsights() {
    return dataSource.getCachedDonationInsights();
  }

  @override
  bool isInsightsCacheValid() {
    return dataSource.isInsightsCacheValid();
  }

  @override
  Future<void> clearInsightsCache() async {
    await dataSource.clearInsightsCache();
  }
}
