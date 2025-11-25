import 'package:donation_app/domain/entities/analytics/point_usage.dart';
import 'package:donation_app/domain/repositories/analytics/analytics_repository.dart';

class TrackPointUsage {
  final AnalyticsRepository repository;

  TrackPointUsage(this.repository);

  Future<void> call({
    required String pointId,
    required String pointTitle,
    String? userId,
  }) async {
    final usage = PointUsage(
      pointId: pointId,
      pointTitle: pointTitle,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await repository.trackPointUsage(usage);
  }
}
