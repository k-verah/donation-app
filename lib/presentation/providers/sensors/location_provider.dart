import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/use_cases/get_current_location.dart';
import 'package:donation_app/domain/use_cases/get_foundations_points.dart';
import 'package:donation_app/domain/use_cases/recommend_foundation.dart';
import 'package:donation_app/domain/use_cases/sort_points.dart';
import 'package:flutter/foundation.dart';

class LocationProvider extends ChangeNotifier {
  final GetCurrentLocation getCurrentLocation;
  final GetFoundationsPoints getFoundationsPoints;
  final SortPoints sortPoints;
  final RecommendFoundation recommendUC;

  LocationProvider({
    required this.getCurrentLocation,
    required this.getFoundationsPoints,
    required this.sortPoints,
    required this.recommendUC,
  });

  static const bogota = GeoPoint(4.7110, -74.0721);

  GeoPoint? _current;
  List<FoundationPoint> _points = [];
  String cause = 'All', access = 'All', schedule = 'All';
  String? recommendationMsg;

  GeoPoint? get current => _current;
  List<FoundationPoint> get points => _points;

  Future<void> init() async {
    _points = await getFoundationsPoints();
    _current = await getCurrentLocation();
    notifyListeners();
  }

  List<(FoundationPoint, double)> sorted() => sortPoints(_points, _current);

  void setFilters({String? causeVal, String? accessVal, String? scheduleVal}) {
    if (causeVal != null) cause = causeVal;
    if (accessVal != null) access = accessVal;
    if (scheduleVal != null) schedule = scheduleVal;
    notifyListeners();
  }

  FoundationPoint? recommend() {
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
}
