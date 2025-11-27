import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class CacheDonationPoints {
  final LocalStorageRepository repository;

  CacheDonationPoints(this.repository);

  Future<void> call(List<FoundationPoint> points) async {
    await repository.cacheDonationPoints(points);
  }
}