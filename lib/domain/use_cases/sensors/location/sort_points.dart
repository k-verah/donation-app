import 'dart:math' show cos, asin, sqrt;
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:flutter/foundation.dart';

import 'sort_points_compute.dart' as compute_helper;

class SortPoints {
  const SortPoints();

  double distance(GeoPoint a, GeoPoint b) {
    const R = 6371000.0;
    final dLat = _deg(b.lat - a.lat), dLon = _deg(b.lng - a.lng);
    final la1 = _deg(a.lat), la2 = _deg(b.lat);
    final h = _h(dLat) + cos(la1) * cos(la2) * _h(dLon);
    return 2 * R * asin(sqrt(h));
  }

  List<(FoundationPoint, double)> call(
    List<FoundationPoint> points,
    GeoPoint? origin,
  ) {
    if (origin == null) return points.map((p) => (p, double.nan)).toList();

    if (points.length > 20) {
      return _sortInMainThread(points, origin);
    }

    return _sortInMainThread(points, origin);
  }

  List<(FoundationPoint, double)> _sortInMainThread(
    List<FoundationPoint> points,
    GeoPoint origin,
  ) {
    final list = points.map((p) => (p, distance(origin, p.pos))).toList();
    list.sort((a, b) => a.$2.compareTo(b.$2));
    return list;
  }

  double _deg(double d) => d * 3.141592653589793 / 180.0;
  double _h(double x) => (1 - cos(x)) / 2;
}
