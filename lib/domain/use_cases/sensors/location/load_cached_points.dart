import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class LoadCachedPoints {
  final LocalStorageRepository repository;

  LoadCachedPoints(this.repository);

  List<FoundationPoint>? call() {
    final cached = repository.getCachedDonationPoints();
    if (cached != null && repository.isCacheValid()) {
      return cached;
    }
    return null;
  }
}