import 'package:donation_app/domain/entities/analytics/filter_usage.dart';
import 'package:donation_app/domain/repositories/analytics/analytics_repository.dart';

class TrackFilterUsage {
  final AnalyticsRepository repository;

  TrackFilterUsage(this.repository);

  Future<void> call({
    required String cause,
    required String access,
    required String schedule,
    String? userId,
  }) async {
    final usage = FilterUsage(
      cause: cause,
      access: access,
      schedule: schedule,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await repository.trackFilterUsage(usage);
  }
}