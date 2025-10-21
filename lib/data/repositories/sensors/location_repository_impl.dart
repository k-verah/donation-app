import 'package:donation_app/data/datasources/sensors/location_datasource.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/repositories/sensors/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource ds;
  LocationRepositoryImpl(this.ds);

  @override
  Future<GeoPoint?> getCurrent() async {
    final p = await ds.currentPosition();
    if (p == null) return null;
    return GeoPoint(p.latitude, p.longitude);
  }
}
