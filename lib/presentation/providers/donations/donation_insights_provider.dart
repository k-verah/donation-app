import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/use_cases/donations/cache_donation_insights.dart';
import 'package:donation_app/domain/use_cases/donations/load_cached_insights.dart';
import 'package:donation_app/presentation/providers/auth/auth_provider.dart';
import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class DonationInsightsProvider extends ChangeNotifier {
  final GetDonationInsightsByFoundation getInsights;
  final CacheDonationInsights cacheInsights;
  final LoadCachedInsights loadCachedInsights;
  final AuthProvider authProvider;
  final LocationProvider locationProvider;
  final Connectivity _connectivity = Connectivity();

  DonationInsightsProvider({
    required this.getInsights,
    required this.cacheInsights,
    required this.loadCachedInsights,
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

  // Cargar desde cache primero, luego refrescar desde red
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

      // 1. Verificar conectividad
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      // 2. Cargar desde cache primero (si no es force refresh)
      if (!forceRefresh) {
        final cachedInsights = loadCachedInsights();
        if (cachedInsights != null && cachedInsights.isNotEmpty) {
          _insights = cachedInsights;
          _isOffline = !hasConnection;
          _lastUpdatedAt = DateTime.now(); // Podrías guardar el timestamp del cache
          notifyListeners(); // Mostrar cache inmediatamente
        }
      }

      // 3. Si hay conexión, cargar datos frescos
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

          // Guardar en cache
          if (freshInsights.isNotEmpty) {
            await cacheInsights(freshInsights);
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

  // Método para refrescar forzadamente
  Future<void> refresh() async {
    await loadInsights(forceRefresh: true);
  }
}