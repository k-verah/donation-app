import 'package:shared_preferences/shared_preferences.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/donation_completion_status.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/domain/entities/sync/sync_status.dart';
import 'package:donation_app/domain/entities/sync/sync_queue_item.dart';
import 'dart:convert';

class LocalStorageDataSource {
  final SharedPreferences _prefs;

  LocalStorageDataSource(this._prefs);

  static const String _keyLastCause = 'last_filter_cause';
  static const String _keyLastAccess = 'last_filter_access';
  static const String _keyLastSchedule = 'last_filter_schedule';
  static const String _keyLastLocationLat = 'last_location_lat';
  static const String _keyLastLocationLng = 'last_location_lng';
  static const String _keyCachedPoints = 'cached_donation_points';
  static const String _keyCacheTimestamp = 'points_cache_timestamp';

  static const String _keyLocalDonations = 'local_donations';
  static const String _keyScheduleDonations = 'schedule_donations';
  static const String _keyPickupDonations = 'pickup_donations';
  static const String _keySyncQueue = 'sync_queue';
  static const String _keyDonationsCacheTimestamp = 'donations_cache_timestamp';

  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    await Future.wait([
      _prefs.setString(_keyLastCause, cause),
      _prefs.setString(_keyLastAccess, access),
      _prefs.setString(_keyLastSchedule, schedule),
    ]);
  }

  Map<String, String> getFilterPreferences() {
    return {
      'cause': _prefs.getString(_keyLastCause) ?? 'All',
      'access': _prefs.getString(_keyLastAccess) ?? 'All',
      'schedule': _prefs.getString(_keyLastSchedule) ?? 'All',
    };
  }

  Future<void> saveLastLocation(GeoPoint location) async {
    await Future.wait([
      _prefs.setDouble(_keyLastLocationLat, location.lat),
      _prefs.setDouble(_keyLastLocationLng, location.lng),
    ]);
  }

  GeoPoint? getLastLocation() {
    final lat = _prefs.getDouble(_keyLastLocationLat);
    final lng = _prefs.getDouble(_keyLastLocationLng);
    if (lat != null && lng != null) {
      return GeoPoint(lat, lng);
    }
    return null;
  }

  Future<void> cacheDonationPoints(List<FoundationPoint> points) async {
    final jsonList = points
        .map((p) => {
              'id': p.id,
              'title': p.title,
              'cause': p.cause,
              'access': p.access,
              'schedule': p.schedule,
              'lat': p.pos.lat,
              'lng': p.pos.lng,
            })
        .toList();

    await Future.wait([
      _prefs.setString(_keyCachedPoints, jsonEncode(jsonList)),
      _prefs.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  List<FoundationPoint>? getCachedDonationPoints() {
    final jsonString = _prefs.getString(_keyCachedPoints);
    if (jsonString == null) return null;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) {
        final map = json as Map<String, dynamic>;
        return FoundationPoint(
          id: map['id'] as String,
          title: map['title'] as String,
          cause: map['cause'] as String,
          access: map['access'] as String,
          schedule: map['schedule'] as String,
          pos: GeoPoint(
            map['lat'] as double,
            map['lng'] as double,
          ),
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }

  bool isCacheValid() {
    final timestamp = _prefs.getInt(_keyCacheTimestamp);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference.inHours < 24;
  }

  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_keyCachedPoints),
      _prefs.remove(_keyCacheTimestamp),
    ]);
  }

  Future<void> saveDonation(Donation donation) async {
    final donations = getDonations();
    final index = donations.indexWhere((d) => d.id == donation.id);
    if (index >= 0) {
      donations[index] = donation;
    } else {
      donations.add(donation);
    }
    await _saveDonationsList(donations);
  }

  Future<void> saveDonations(List<Donation> donations) async {
    final existing = getDonations();
    final Map<String, Donation> merged = {
      for (final d in existing) d.id!: d,
      for (final d in donations) d.id!: d,
    };
    await _saveDonationsList(merged.values.toList());
    await _prefs.setInt(
        _keyDonationsCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  List<Donation> getDonations() {
    final jsonString = _prefs.getString(_keyLocalDonations);
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Donation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<Donation> getDonationsByUid(String uid) {
    return getDonations().where((d) => d.uid == uid).toList();
  }

  List<Donation> getPendingDonations() {
    return getDonations().where((d) => d.syncStatus.needsSync).toList();
  }

  Future<void> updateDonationSyncStatus(String id, SyncStatus status) async {
    final donations = getDonations();
    final index = donations.indexWhere((d) => d.id == id);
    if (index >= 0) {
      donations[index] = donations[index].copyWith(syncStatus: status);
      await _saveDonationsList(donations);
    }
  }

  Future<void> _saveDonationsList(List<Donation> donations) async {
    final jsonList = donations.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyLocalDonations, jsonEncode(jsonList));
  }

  bool isDonationsCacheValid() {
    final timestamp = _prefs.getInt(_keyDonationsCacheTimestamp);
    if (timestamp == null) return false;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime).inMinutes < 5;
  }

  List<Donation> getAvailableDonations(String uid) {
    return getDonationsByUid(uid)
        .where((d) => d.completionStatus.isAvailable)
        .toList();
  }

  List<Donation> getPendingCompletionDonations(String uid) {
    return getDonationsByUid(uid)
        .where((d) => d.completionStatus.isPendingCompletion)
        .toList();
  }

  List<Donation> getCompletedDonations(String uid) {
    return getDonationsByUid(uid)
        .where((d) => d.completionStatus.isCompleted)
        .toList();
  }

  Future<void> updateDonationCompletionStatus(
    String id,
    DonationCompletionStatus status,
  ) async {
    final donations = getDonations();
    final index = donations.indexWhere((d) => d.id == id);
    if (index >= 0) {
      donations[index] = donations[index].copyWith(completionStatus: status);
      await _saveDonationsList(donations);
    }
  }

  Future<void> updateDonationsCompletionStatus(
    List<String> ids,
    DonationCompletionStatus status,
  ) async {
    final donations = getDonations();
    for (final id in ids) {
      final index = donations.indexWhere((d) => d.id == id);
      if (index >= 0) {
        donations[index] = donations[index].copyWith(completionStatus: status);
      }
    }
    await _saveDonationsList(donations);
  }

  Future<void> saveScheduleDonation(ScheduleDonation schedule) async {
    final schedules = getScheduleDonations();
    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }
    await _saveSchedulesList(schedules);
  }

  List<ScheduleDonation> getScheduleDonations() {
    final jsonString = _prefs.getString(_keyScheduleDonations);
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map(
              (json) => ScheduleDonation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<ScheduleDonation> getSchedulesByUid(String uid) {
    return getScheduleDonations().where((s) => s.uid == uid).toList();
  }

  List<ScheduleDonation> getPendingSchedules() {
    return getScheduleDonations().where((s) => s.syncStatus.needsSync).toList();
  }

  Future<void> updateScheduleSyncStatus(String id, SyncStatus status) async {
    final schedules = getScheduleDonations();
    final index = schedules.indexWhere((s) => s.id == id);
    if (index >= 0) {
      schedules[index] = schedules[index].copyWith(syncStatus: status);
      await _saveSchedulesList(schedules);
    }
  }

  Future<void> _saveSchedulesList(List<ScheduleDonation> schedules) async {
    final jsonList = schedules.map((s) => s.toJson()).toList();
    await _prefs.setString(_keyScheduleDonations, jsonEncode(jsonList));
  }

  List<ScheduleDonation> getUndeliveredSchedules(String uid) {
    return getSchedulesByUid(uid).where((s) => !s.isDelivered).toList();
  }

  List<ScheduleDonation> getDeliveredSchedules(String uid) {
    return getSchedulesByUid(uid).where((s) => s.isDelivered).toList();
  }

  Future<void> markScheduleAsDelivered(String id) async {
    final schedules = getScheduleDonations();
    final index = schedules.indexWhere((s) => s.id == id);
    if (index >= 0) {
      schedules[index] = schedules[index].copyWith(
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );
      await _saveSchedulesList(schedules);
    }
  }

  Future<void> savePickupDonation(PickupDonation pickup) async {
    final pickups = getPickupDonations();
    final index = pickups.indexWhere((p) => p.id == pickup.id);
    if (index >= 0) {
      pickups[index] = pickup;
    } else {
      pickups.add(pickup);
    }
    await _savePickupsList(pickups);
  }

  List<PickupDonation> getPickupDonations() {
    final jsonString = _prefs.getString(_keyPickupDonations);
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => PickupDonation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<PickupDonation> getPickupsByUid(String uid) {
    return getPickupDonations().where((p) => p.uid == uid).toList();
  }

  List<PickupDonation> getPendingPickups() {
    return getPickupDonations().where((p) => p.syncStatus.needsSync).toList();
  }

  Future<void> updatePickupSyncStatus(String id, SyncStatus status) async {
    final pickups = getPickupDonations();
    final index = pickups.indexWhere((p) => p.id == id);
    if (index >= 0) {
      pickups[index] = pickups[index].copyWith(syncStatus: status);
      await _savePickupsList(pickups);
    }
  }

  Future<void> _savePickupsList(List<PickupDonation> pickups) async {
    final jsonList = pickups.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyPickupDonations, jsonEncode(jsonList));
  }

  List<PickupDonation> getUndeliveredPickups(String uid) {
    return getPickupsByUid(uid).where((p) => !p.isDelivered).toList();
  }

  List<PickupDonation> getDeliveredPickups(String uid) {
    return getPickupsByUid(uid).where((p) => p.isDelivered).toList();
  }

  Future<void> markPickupAsDelivered(String id) async {
    final pickups = getPickupDonations();
    final index = pickups.indexWhere((p) => p.id == id);
    if (index >= 0) {
      pickups[index] = pickups[index].copyWith(
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );
      await _savePickupsList(pickups);
    }
  }

  bool hasBookingForDate(String uid, DateTime date) {
    final dayKey = _dayKey(date);

    final schedules = getSchedulesByUid(uid);
    final hasSchedule = schedules.any((s) => _dayKey(s.date) == dayKey);
    if (hasSchedule) return true;

    final pickups = getPickupsByUid(uid);
    final hasPickup = pickups.any((p) => _dayKey(p.date) == dayKey);
    if (hasPickup) return true;

    return false;
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> addToSyncQueue(SyncQueueItem item) async {
    final queue = getSyncQueue();
    queue.add(item);
    await _saveSyncQueue(queue);
  }

  List<SyncQueueItem> getSyncQueue() {
    final jsonString = _prefs.getString(_keySyncQueue);
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SyncQueueItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<SyncQueueItem> getPendingSyncItems() {
    return getSyncQueue().where((item) => item.canRetry).toList();
  }

  Future<void> updateSyncQueueItem(SyncQueueItem item) async {
    final queue = getSyncQueue();
    final index = queue.indexWhere((q) => q.id == item.id);
    if (index >= 0) {
      queue[index] = item;
      await _saveSyncQueue(queue);
    }
  }

  Future<void> removeFromSyncQueue(String itemId) async {
    final queue = getSyncQueue();
    queue.removeWhere((q) => q.id == itemId);
    await _saveSyncQueue(queue);
  }

  Future<void> clearSyncQueue() async {
    await _prefs.remove(_keySyncQueue);
  }

  Future<void> _saveSyncQueue(List<SyncQueueItem> queue) async {
    final jsonList = queue.map((q) => q.toJson()).toList();
    await _prefs.setString(_keySyncQueue, jsonEncode(jsonList));
  }

  bool hasPendingSync() {
    return getPendingSyncItems().isNotEmpty;
  }

  Future<void> clearAllLocalData() async {
    await Future.wait([
      _prefs.remove(_keyLocalDonations),
      _prefs.remove(_keyScheduleDonations),
      _prefs.remove(_keyPickupDonations),
      _prefs.remove(_keySyncQueue),
      _prefs.remove(_keyDonationsCacheTimestamp),
      clearCache(),
    ]);
  }
}
