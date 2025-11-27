import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class LoadLastLocation {
  final LocalStorageRepository repository;

  LoadLastLocation(this.repository);

  GeoPoint? call() {
    return repository.getLastLocation();
  }
}