import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/use_cases/sensors/location/get_current_location.dart';
import 'package:donation_app/domain/use_cases/sensors/location/get_foundations_points.dart';
import 'package:donation_app/domain/use_cases/sensors/location/recommend_foundation.dart';
import 'package:donation_app/domain/use_cases/sensors/location/sort_points.dart';
import 'package:donation_app/domain/use_cases/sensors/location/save_filter_preferences.dart';
import 'package:donation_app/domain/use_cases/sensors/location/load_filter_preferences.dart';
import 'package:donation_app/domain/use_cases/sensors/location/save_last_location.dart';
import 'package:donation_app/domain/use_cases/sensors/location/load_last_location.dart';
import 'package:donation_app/domain/use_cases/sensors/location/cache_donation_points.dart';
import 'package:donation_app/domain/use_cases/sensors/location/load_cached_points.dart';
import 'package:flutter/foundation.dart';

class LocationProvider extends ChangeNotifier {
  final GetCurrentLocation getCurrentLocation;
  final GetFoundationsPoints getFoundationsPoints;
  final SortPoints sortPoints;
  final RecommendFoundation recommendUC;
  final SaveFilterPreferences saveFilterPreferences;
  final LoadFilterPreferences loadFilterPreferences;
  final SaveLastLocation saveLastLocation;
  final LoadLastLocation loadLastLocation;
  final CacheDonationPoints cacheDonationPoints;
  final LoadCachedPoints loadCachedPoints;

  LocationProvider({
    required this.getCurrentLocation,
    required this.getFoundationsPoints,
    required this.sortPoints,
    required this.recommendUC,
    required this.saveFilterPreferences,
    required this.loadFilterPreferences,
    required this.saveLastLocation,
    required this.loadLastLocation,
    required this.cacheDonationPoints,
    required this.loadCachedPoints,
  });

  static const bogota = GeoPoint(4.7110, -74.0721);

  GeoPoint? _current;
  List<FoundationPoint> _points = [];
  String cause = 'All', access = 'All', schedule = 'All';
  String? recommendationMsg;
  FoundationPoint? _forcedRecommended;

  GeoPoint? get current => _current;
  List<FoundationPoint> get points => _points;
  FoundationPoint? get forcedRecommended => _forcedRecommended;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Future<void> init() async {
    final savedFilters = loadFilterPreferences();
    cause = savedFilters['cause'] ?? 'All';
    access = savedFilters['access'] ?? 'All';
    schedule = savedFilters['schedule'] ?? 'All';

    final cachedPoints = loadCachedPoints();
    if (cachedPoints != null && cachedPoints.isNotEmpty) {
      _points = cachedPoints;
      notifyListeners();
    }

    final lastLocation = loadLastLocation();
    if (lastLocation != null) {
      _current = lastLocation;
      notifyListeners();
    }

    await _loadFreshData();
  }

  Future<void> _loadFreshData() async {
    try {
      final results = await Future.wait([
        getFoundationsPoints(),
        getCurrentLocation(),
      ]).timeout(const Duration(seconds: 10));

      _points = results[0] as List<FoundationPoint>;
      _current = results[1] as GeoPoint?;
      _isOffline = false;

      if (_points.isNotEmpty) {
        await cacheDonationPoints(_points);
      }

      if (_current != null) {
        await saveLastLocation(_current!);
      }

      notifyListeners();
    } catch (e) {
      _isOffline = true;

      if (_points.isEmpty) {}
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadFreshData();
  }

  List<(FoundationPoint, double)> sorted() => sortPoints(_points, _current);

  List<FoundationPoint> getFilteredPoints() {
    return _points.where((p) {
      final c = cause == 'All' || p.cause == cause;
      final a = access == 'All' || p.access == access;
      final s = schedule == 'All' || p.schedule == schedule;
      return c && a && s;
    }).toList();
  }

  List<(FoundationPoint, double)> getFilteredAndSorted() {
    final filtered = getFilteredPoints();
    return sortPoints(filtered, _current);
  }

  bool hasActiveFilters() {
    return cause != 'All' || access != 'All' || schedule != 'All';
  }

  void setFilters({String? causeVal, String? accessVal, String? scheduleVal}) {
    if (causeVal != null) cause = causeVal;
    if (accessVal != null) access = accessVal;
    if (scheduleVal != null) schedule = scheduleVal;


    _forcedRecommended = null;

    saveFilterPreferences(
      cause: cause,
      access: access,
      schedule: schedule,
    );

    notifyListeners();
  }

  FoundationPoint? recommend() {

    if (_forcedRecommended != null) {
      return _forcedRecommended;
    }
    
    final res = recommendUC(
      points: _points,
      cause: cause,
      access: access,
      schedule: schedule,
      origin: _current,
    );
    recommendationMsg = res.message;
    notifyListeners();
    return res.best;
  }

  void setRecommendedFoundation(FoundationPoint? foundation) {
    _forcedRecommended = foundation;
    notifyListeners();
  }

  void clearRecommendedFoundation() {
    _forcedRecommended = null;
    notifyListeners();
  }
}
