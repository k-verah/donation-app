import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/use_cases/sensors/location/sort_points.dart';

class RecommendFoundation {
  final SortPoints sorter;
  const RecommendFoundation(this.sorter);

  ({FoundationPoint? best, String? message}) call({
    required List<FoundationPoint> points,
    required String cause,
    required String access,
    required String schedule,
    required GeoPoint? origin,
  }) {
    final filtered = points.where((p) {
      final c = cause == 'All' || p.cause == cause;
      final a = access == 'All' || p.access == access;
      final s = schedule == 'All' || p.schedule == schedule;
      return c && a && s;
    }).toList();

    if (filtered.isEmpty) {
      return (
        best: null,
        message:
            'No donation point matches your preferences. Try adjusting your filters.',
      );
    }

    final sorted = sorter(filtered, origin);
    return (
      best: sorted.isNotEmpty ? sorted.first.$1 : filtered.first,
      message: null,
    );
  }
}
