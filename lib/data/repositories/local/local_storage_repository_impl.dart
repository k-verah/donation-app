import 'package:donation_app/data/datasources/local/local_storage_datasource.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class LocalStorageRepositoryImpl implements LocalStorageRepository {
  final LocalStorageDataSource dataSource;

  LocalStorageRepositoryImpl(this.dataSource);

  @override
  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    await dataSource.saveFilterPreferences(
      cause: cause,
      access: access,
      schedule: schedule,
    );
  }

  @override
  Map<String, String> getFilterPreferences() {
    return dataSource.getFilterPreferences();
  }

  @override
  Future<void> saveLastLocation(GeoPoint location) async {
    await dataSource.saveLastLocation(location);
  }

  @override
  GeoPoint? getLastLocation() {
    return dataSource.getLastLocation();
  }

  @override
  Future<void> cacheDonationPoints(List<FoundationPoint> points) async {
    await dataSource.cacheDonationPoints(points);
  }

  @override
  List<FoundationPoint>? getCachedDonationPoints() {
    return dataSource.getCachedDonationPoints();
  }

  @override
  bool isCacheValid() {
    return dataSource.isCacheValid();
  }

  @override
  Future<void> clearCache() async {
    await dataSource.clearCache();
  }
}