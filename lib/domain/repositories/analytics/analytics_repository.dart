import 'package:donation_app/domain/entities/analytics/filter_combination_stats.dart';
import 'package:donation_app/domain/entities/analytics/filter_usage.dart';
import 'package:donation_app/domain/entities/analytics/point_stats.dart';
import 'package:donation_app/domain/entities/analytics/point_usage.dart';

abstract class AnalyticsRepository {
  Future<void> trackFilterUsage(FilterUsage usage);
  Future<void> trackPointUsage(PointUsage usage);
  Future<List<FilterCombinationStats>> getFilterCombinationStats();
  Future<List<PointStats>> getPointUsageStats();
}