import 'package:donation_app/domain/entities/analytics/filter_combination_stats.dart';
import 'package:donation_app/domain/entities/analytics/point_stats.dart';
import 'package:donation_app/domain/use_cases/sensors/location/get_filter_combination_stats.dart';
import 'package:donation_app/domain/use_cases/sensors/location/get_point_usage_stats.dart';
import 'package:donation_app/domain/use_cases/sensors/location/track_filter_usage.dart';
import 'package:donation_app/domain/use_cases/sensors/location/track_point_usage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsProvider extends ChangeNotifier {
  final TrackFilterUsage _trackFilterUsage;
  final TrackPointUsage _trackPointUsage;
  final GetFilterCombinationStats _getFilterCombinationStats;
  final GetPointUsageStats _getPointUsageStats;
  final FirebaseAuth _auth;

  AnalyticsProvider({
    required TrackFilterUsage trackFilterUsage,
    required TrackPointUsage trackPointUsage,
    required GetFilterCombinationStats getFilterCombinationStats,
    required GetPointUsageStats getPointUsageStats,
    FirebaseAuth? auth,
  })  : _trackFilterUsage = trackFilterUsage,
        _trackPointUsage = trackPointUsage,
        _getFilterCombinationStats = getFilterCombinationStats,
        _getPointUsageStats = getPointUsageStats,
        _auth = auth ?? FirebaseAuth.instance;

  List<FilterCombinationStats> _filterStats = [];
  List<PointStats> _pointStats = [];
  bool _loading = false;

  List<FilterCombinationStats> get filterStats => _filterStats;
  List<PointStats> get pointStats => _pointStats;
  bool get loading => _loading;

  Future<void> trackFilterUsage({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    final userId = _auth.currentUser?.uid;
    await _trackFilterUsage(
      cause: cause,
      access: access,
      schedule: schedule,
      userId: userId,
    );
  }

  Future<void> trackPointUsage({
    required String pointId,
    required String pointTitle,
  }) async {
    final userId = _auth.currentUser?.uid;
    await _trackPointUsage(
      pointId: pointId,
      pointTitle: pointTitle,
      userId: userId,
    );
  }

  Future<void> loadStats() async {
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getFilterCombinationStats.call(),
        _getPointUsageStats.call(),
      ]);

      _filterStats = results[0] as List<FilterCombinationStats>;
      _pointStats = results[1] as List<PointStats>;
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
