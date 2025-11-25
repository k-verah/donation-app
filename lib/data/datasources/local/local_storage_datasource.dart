import 'package:shared_preferences/shared_preferences.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'dart:convert';

class LocalStorageDataSource {
  final SharedPreferences _prefs;

  LocalStorageDataSource(this._prefs);

  // Keys para SharedPreferences
  static const String _keyLastCause = 'last_filter_cause';
  static const String _keyLastAccess = 'last_filter_access';
  static const String _keyLastSchedule = 'last_filter_schedule';
  static const String _keyLastLocationLat = 'last_location_lat';
  static const String _keyLastLocationLng = 'last_location_lng';
  static const String _keyCachedPoints = 'cached_donation_points';
  static const String _keyCacheTimestamp = 'points_cache_timestamp';

  // Guardar preferencias de filtros
  Future<void> saveFilterPreferences({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    await Future.wait([
      _prefs.setString(_keyLastCause, cause),
      _prefs.setString(_keyLastAccess, access),
      _prefs.setString(_keyLastSchedule, schedule),
    ]);
  }

  // Cargar preferencias de filtros
  Map<String, String> getFilterPreferences() {
    return {
      'cause': _prefs.getString(_keyLastCause) ?? 'All',
      'access': _prefs.getString(_keyLastAccess) ?? 'All',
      'schedule': _prefs.getString(_keyLastSchedule) ?? 'All',
    };
  }

  // Guardar última ubicación conocida
  Future<void> saveLastLocation(GeoPoint location) async {
    await Future.wait([
      _prefs.setDouble(_keyLastLocationLat, location.lat),
      _prefs.setDouble(_keyLastLocationLng, location.lng),
    ]);
  }

  // Cargar última ubicación conocida
  GeoPoint? getLastLocation() {
    final lat = _prefs.getDouble(_keyLastLocationLat);
    final lng = _prefs.getDouble(_keyLastLocationLng);
    if (lat != null && lng != null) {
      return GeoPoint(lat, lng);
    }
    return null;
  }

  // Guardar cache de puntos de donación
  Future<void> cacheDonationPoints(List<FoundationPoint> points) async {
    final jsonList = points.map((p) => {
      'id': p.id,
      'title': p.title,
      'cause': p.cause,
      'access': p.access,
      'schedule': p.schedule,
      'lat': p.pos.lat,
      'lng': p.pos.lng,
    }).toList();
    
    await Future.wait([
      _prefs.setString(_keyCachedPoints, jsonEncode(jsonList)),
      _prefs.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  // Cargar cache de puntos de donación
  List<FoundationPoint>? getCachedDonationPoints() {
    final jsonString = _prefs.getString(_keyCachedPoints);
    if (jsonString == null) return null;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) {
        final map = json as Map<String, dynamic>;
        return FoundationPoint(
          id: map['id'] as String,
          title: map['title'] as String,
          cause: map['cause'] as String,
          access: map['access'] as String,
          schedule: map['schedule'] as String,
          pos: GeoPoint(
            map['lat'] as double,
            map['lng'] as double,
          ),
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }

  // Verificar si el cache es válido (menos de 24 horas)
  bool isCacheValid() {
    final timestamp = _prefs.getInt(_keyCacheTimestamp);
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    return difference.inHours < 24; // Cache válido por 24 horas
  }

  // Limpiar cache
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_keyCachedPoints),
      _prefs.remove(_keyCacheTimestamp),
    ]);
  }
}

