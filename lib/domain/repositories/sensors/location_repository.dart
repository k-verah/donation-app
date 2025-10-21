import 'package:donation_app/domain/entities/sensors/geo_point.dart';

abstract class LocationRepository {
  Future<GeoPoint?> getCurrent();
}
