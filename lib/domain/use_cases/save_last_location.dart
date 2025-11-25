import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class SaveLastLocation {
  final LocalStorageRepository repository;

  SaveLastLocation(this.repository);

  Future<void> call(GeoPoint location) async {
    await repository.saveLastLocation(location);
  }
}