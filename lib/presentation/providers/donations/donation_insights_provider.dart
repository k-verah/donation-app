import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/use_cases/donations/cache_donation_insights.dart';
import 'package:donation_app/domain/use_cases/donations/load_cached_insights.dart';
import 'package:donation_app/domain/use_cases/donations/manage_insights_storage.dart';
import 'package:donation_app/domain/use_cases/donations/insights_cache_strategy.dart';
import 'package:donation_app/presentation/providers/auth/auth_provider.dart';
import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class DonationInsightsProvider extends ChangeNotifier {
  final GetDonationInsightsByFoundation getInsights;
  final CacheDonationInsights cacheInsights;
  final LoadCachedInsights loadCachedInsights;
  final ManageInsightsStorage manageStorage;
  final InsightsCacheStrategy cacheStrategy;
  final AuthProvider authProvider;
  final LocationProvider locationProvider;
  final Connectivity _connectivity = Connectivity();

  DonationInsightsProvider({
    required this.getInsights,
    required this.cacheInsights,
    required this.loadCachedInsights,
    required this.manageStorage,
    required this.cacheStrategy,
    required this.authProvider,
    required this.locationProvider,
  });

  List<FoundationInsight> _insights = [];
  bool _loading = false;
  String? _error;
  bool _isOffline = false;
  DateTime? _lastUpdatedAt;

  List<FoundationInsight> get insights => _insights;
  bool get loading => _loading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;


  Future<void> loadInsights({bool forceRefresh = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = authProvider.user;
      if (user == null || user.uid.isEmpty) {
        _error = 'User not authenticated';
        _loading = false;
        notifyListeners();
        return;
      }


      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      // Estrategia de caching multi-nivel: Memory -> Persistent -> Network
      if (!forceRefresh) {
        final cacheResult = await cacheStrategy.getCachedData(
          userId: user.uid,
          forceRefresh: false,
        );

        if (cacheResult.hasData) {
          _insights = cacheResult.data!;
          _isOffline = !hasConnection || cacheResult.isStale;
          _lastUpdatedAt = DateTime.now();

          // Si el cache está stale y tenemos conexión, continuamos para refrescar
          if (!cacheResult.isStale || !hasConnection) {
            notifyListeners();
            if (!hasConnection) {
              _loading = false;
              return;
            }
          }
        }
      }

      if (hasConnection) {
        try {
          final userLocation = locationProvider.current;

          final freshInsights = await getInsights(
            userId: user.uid,
            userLocation: userLocation,
          );

          _insights = freshInsights;
          _isOffline = false;
          _lastUpdatedAt = DateTime.now();

          if (freshInsights.isNotEmpty) {
            // Guardar en cache usando estrategia multi-nivel
            await cacheStrategy.setCachedData(freshInsights);

            // También guardar usando el método tradicional para compatibilidad
            await cacheInsights(freshInsights);

            // Optimizar almacenamiento después de guardar
            await manageStorage.optimizeStorage();

            // Limpiar datos antiguos si es necesario
            await manageStorage.cleanupIfNeeded();
          }

          _error = null;
        } catch (e) {
          // Si falla la carga pero tenemos cache, mantenerlo
          if (_insights.isEmpty) {
            _error = 'Error loading insights: $e';
            debugPrint(_error);
          } else {
            _isOffline = true;
            debugPrint('Error loading fresh data, using cache: $e');
          }
        }
      } else {
        // Sin conexión: usar cache si está disponible
        if (_insights.isEmpty) {
          _error = 'No internet connection and no cached data available';
        } else {
          _isOffline = true;
        }
      }
    } catch (e) {
      _error = 'Error loading insights: $e';
      debugPrint(_error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  Future<void> refresh() async {
    await loadInsights(forceRefresh: true);
  }

  // Obtener información del almacenamiento
  StorageInfo getStorageInfo() {
    return manageStorage.getStorageInfo();
  }

  // Obtener estadísticas del almacenamiento
  StorageStats getStorageStats() {
    return manageStorage.getStorageStats();
  }

  // Limpiar cache manualmente
  Future<void> clearCache() async {
    await manageStorage.repository.clearInsightsCache();
    _insights = [];
    _lastUpdatedAt = null;
    notifyListeners();
  }

  // Verificar integridad de datos
  bool verifyDataIntegrity() {
    return manageStorage.verifyDataIntegrity();
  }

  // Obtener estadísticas del cache
  CacheStats getCacheStats() {
    return cacheStrategy.getCacheStats();
  }

  // Cache warming: Pre-cargar datos en memoria
  Future<void> warmCache() async {
    await cacheStrategy.warmCache();
  }

  // Invalidar cache por evento
  Future<void> invalidateCacheOnEvent(CacheInvalidationEvent event) async {
    await cacheStrategy.invalidateOnEvent(event);
    _insights = [];
    _lastUpdatedAt = null;
    notifyListeners();
  }

  // Forzar sincronización manual (simplemente recarga desde red)
  Future<void> forceSync() async {
    await loadInsights(forceRefresh: true);
  }
}

