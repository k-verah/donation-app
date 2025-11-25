import 'package:donation_app/data/datasources/analytics/analytics_datasource.dart';
import 'package:donation_app/domain/entities/analytics/filter_combination_stats.dart';
import 'package:donation_app/domain/entities/analytics/filter_usage.dart';
import 'package:donation_app/domain/entities/analytics/point_stats.dart';
import 'package:donation_app/domain/entities/analytics/point_usage.dart';
import 'package:donation_app/domain/repositories/analytics/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsDataSource dataSource;

  AnalyticsRepositoryImpl(this.dataSource);

  @override
  Future<void> trackFilterUsage(FilterUsage usage) async {
    await dataSource.trackFilterUsage(usage);
  }

  @override
  Future<void> trackPointUsage(PointUsage usage) async {
    await dataSource.trackPointUsage(usage);
  }

  @override
  Future<List<FilterCombinationStats>> getFilterCombinationStats() async {
    final stats = await dataSource.getFilterUsageStats();
    return stats.map((s) => FilterCombinationStats(
          cause: s['cause'] as String,
          access: s['access'] as String,
          schedule: s['schedule'] as String,
          usageCount: s['count'] as int,
        )).toList();
  }

  @override
  Future<List<PointStats>> getPointUsageStats() async {
    final stats = await dataSource.getPointUsageStats();
    return stats.map((s) => PointStats(
          pointId: s['pointId'] as String,
          pointTitle: s['pointTitle'] as String,
          usageCount: s['count'] as int,
        )).toList();
  }
}