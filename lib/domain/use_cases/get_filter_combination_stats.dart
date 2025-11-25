import 'package:donation_app/domain/entities/analytics/filter_combination_stats.dart';
import 'package:donation_app/domain/repositories/analytics/analytics_repository.dart';

class GetFilterCombinationStats {
  final AnalyticsRepository repository;

  GetFilterCombinationStats(this.repository);

  Future<List<FilterCombinationStats>> call() async {
    return await repository.getFilterCombinationStats();
  }
}