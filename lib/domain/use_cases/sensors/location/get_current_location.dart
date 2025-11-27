import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import '../../../repositories/sensors/location_repository.dart';

class GetCurrentLocation {
  final LocationRepository repo;
  const GetCurrentLocation(this.repo);
  Future<GeoPoint?> call() => repo.getCurrent();
}
