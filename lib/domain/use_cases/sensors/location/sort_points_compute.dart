import 'dart:math' show cos, asin, sqrt;
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';

// ✅ Funciones helper de nivel superior (top-level) para usar con compute
double _deg(double d) => d * 3.141592653589793 / 180.0;
double _h(double x) => (1 - cos(x)) / 2;

// Función top-level para usar con compute (debe ser serializable)
List<(FoundationPoint, double)> _sortPointsInIsolate(
  Map<String, dynamic> data,
) {
  final points = data['points'] as List<FoundationPoint>;
  final origin = data['origin'] as GeoPoint?;

  if (origin == null) {
    return points.map((p) => (p, double.nan)).toList();
  }

  double distance(GeoPoint a, GeoPoint b) {
    const R = 6371000.0;
    final dLat = _deg(b.lat - a.lat), dLon = _deg(b.lng - a.lng);
    final la1 = _deg(a.lat), la2 = _deg(b.lat);
    final h = _h(dLat) + cos(la1) * cos(la2) * _h(dLon);
    return 2 * R * asin(sqrt(h));
  }

  final list = points.map((p) => (p, distance(origin, p.pos))).toList();
  list.sort((a, b) => a.$2.compareTo(b.$2));
  return list;
}

// Clase helper para serialización
class SortPointsData {
  final List<FoundationPoint> points;
  final GeoPoint? origin;

  SortPointsData({required this.points, this.origin});

  Map<String, dynamic> toMap() => {
        'points': points,
        'origin': origin,
      };
}
