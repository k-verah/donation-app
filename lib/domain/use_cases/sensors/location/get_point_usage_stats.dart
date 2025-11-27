import 'package:donation_app/domain/entities/analytics/point_stats.dart';
import 'package:donation_app/domain/repositories/analytics/analytics_repository.dart';

class GetPointUsageStats {
  final AnalyticsRepository repository;

  GetPointUsageStats(this.repository);

  Future<List<PointStats>> call() async {
    return await repository.getPointUsageStats();
  }
}