import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';

abstract class LocalStorageRepository {
  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  });
  
  Map<String, String> getFilterPreferences();
  
  Future<void> saveLastLocation(GeoPoint location);
  GeoPoint? getLastLocation();
  
  Future<void> cacheDonationPoints(List<FoundationPoint> points);
  List<FoundationPoint>? getCachedDonationPoints();
  bool isCacheValid();
  Future<void> clearCache();
}