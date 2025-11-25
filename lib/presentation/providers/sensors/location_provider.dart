import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/use_cases/get_current_location.dart';
import 'package:donation_app/domain/use_cases/get_foundations_points.dart';
import 'package:donation_app/domain/use_cases/recommend_foundation.dart';
import 'package:donation_app/domain/use_cases/sort_points.dart';
import 'package:donation_app/domain/use_cases/save_filter_preferences.dart';
import 'package:donation_app/domain/use_cases/load_filter_preferences.dart';
import 'package:donation_app/domain/use_cases/save_last_location.dart';
import 'package:donation_app/domain/use_cases/load_last_location.dart';
import 'package:donation_app/domain/use_cases/cache_donation_points.dart';
import 'package:donation_app/domain/use_cases/load_cached_points.dart';
import 'package:flutter/foundation.dart';

class LocationProvider extends ChangeNotifier {
  final GetCurrentLocation getCurrentLocation;
  final GetFoundationsPoints getFoundationsPoints;
  final SortPoints sortPoints;
  final RecommendFoundation recommendUC;
  final SaveFilterPreferences saveFilterPreferences;
  final LoadFilterPreferences loadFilterPreferences;
  final SaveLastLocation saveLastLocation;
  final LoadLastLocation loadLastLocation;
  final CacheDonationPoints cacheDonationPoints;
  final LoadCachedPoints loadCachedPoints;

  LocationProvider({
    required this.getCurrentLocation,
    required this.getFoundationsPoints,
    required this.sortPoints,
    required this.recommendUC,
    required this.saveFilterPreferences,
    required this.loadFilterPreferences,
    required this.saveLastLocation,
    required this.loadLastLocation,
    required this.cacheDonationPoints,
    required this.loadCachedPoints,
  });

  static const bogota = GeoPoint(4.7110, -74.0721);

  GeoPoint? _current;
  List<FoundationPoint> _points = [];
  String cause = 'All', access = 'All', schedule = 'All';
  String? recommendationMsg;

  GeoPoint? get current => _current;
  List<FoundationPoint> get points => _points;

  // ESTRATEGIA: Cargar datos desde local storage primero, luego actualizar
  Future<void> init() async {
    // 1. Cargar preferencias de filtros guardadas
    final savedFilters = loadFilterPreferences();
    cause = savedFilters['cause'] ?? 'All';
    access = savedFilters['access'] ?? 'All';
    schedule = savedFilters['schedule'] ?? 'All';

    // 2. Intentar cargar puntos desde cache
    final cachedPoints = loadCachedPoints();
    if (cachedPoints != null && cachedPoints.isNotEmpty) {
      _points = cachedPoints;
      notifyListeners(); // Mostrar cache inmediatamente
    }

    // 3. Cargar última ubicación conocida
    final lastLocation = loadLastLocation();
    if (lastLocation != null) {
      _current = lastLocation;
      notifyListeners();
    }

    // 4. Cargar datos frescos en paralelo
    try {
      final results = await Future.wait([
        getFoundationsPoints(),
        getCurrentLocation(),
      ]);
      
      _points = results[0] as List<FoundationPoint>;
      _current = results[1] as GeoPoint?;
      
      // Guardar en cache
      if (_points.isNotEmpty) {
        await cacheDonationPoints(_points);
      }
      
      // Guardar última ubicación
      if (_current != null) {
        await saveLastLocation(_current!);
      }
      
      notifyListeners();
    } catch (e) {
      // Si falla la carga, usar cache si está disponible
      debugPrint('Error loading fresh data, using cache: $e');
    }
  }

  List<(FoundationPoint, double)> sorted() => sortPoints(_points, _current);

  List<FoundationPoint> getFilteredPoints() {
    return _points.where((p) {
      final c = cause == 'All' || p.cause == cause;
      final a = access == 'All' || p.access == access;
      final s = schedule == 'All' || p.schedule == schedule;
      return c && a && s;
    }).toList();
  }

  List<(FoundationPoint, double)> getFilteredAndSorted() {
    final filtered = getFilteredPoints();
    return sortPoints(filtered, _current);
  }

  bool hasActiveFilters() {
    return cause != 'All' || access != 'All' || schedule != 'All';
  }

  // Guardar preferencias cuando cambian los filtros
  void setFilters({String? causeVal, String? accessVal, String? scheduleVal}) {
    if (causeVal != null) cause = causeVal;
    if (accessVal != null) access = accessVal;
    if (scheduleVal != null) schedule = scheduleVal;
    
    // Guardar en local storage
    saveFilterPreferences(
      cause: cause,
      access: access,
      schedule: schedule,
    );
    
    notifyListeners();
  }

  FoundationPoint? recommend() {
    final res = recommendUC(
      points: _points,
      cause: cause,
      access: access,
      schedule: schedule,
      origin: _current,
    );
    recommendationMsg = res.message;
    notifyListeners();
    return res.best;
  }
}
