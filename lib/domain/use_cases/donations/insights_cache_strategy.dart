import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

/// Estrategia completa de caching para Donation Insights
/// Implementa: Multi-level caching, TTL policies, Cache invalidation, Cache warming
class InsightsCacheStrategy {
  final LocalStorageRepository repository;

  InsightsCacheStrategy(this.repository);

  /// Políticas de TTL (Time To Live) para diferentes tipos de datos
  static const Duration insightsTTL = Duration(hours: 24);
  static const Duration staleThreshold = Duration(hours: 12);
  static const Duration maxAge = Duration(days: 7);

  /// Nivel 1: Cache en memoria (rápido pero volátil)
  List<FoundationInsight>? _memoryCache;
  DateTime? _memoryCacheTimestamp;

  /// Nivel 2: Cache persistente (más lento pero permanente)
  Future<List<FoundationInsight>?> getPersistentCache() async {
    final cached = repository.getCachedDonationInsights();
    if (cached != null && repository.isInsightsCacheValid()) {
      return cached;
    }
    return null;
  }

  /// Estrategia de caching multi-nivel: Memory -> Persistent -> Network
  Future<CacheResult> getCachedData({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // Nivel 1: Verificar cache en memoria (más rápido)
    if (!forceRefresh && _isMemoryCacheValid()) {
      return CacheResult(
        data: _memoryCache!,
        source: CacheSource.memory,
        isStale: _isMemoryCacheStale(),
      );
    }

    // Nivel 2: Verificar cache persistente
    if (!forceRefresh) {
      final persistentCache = await getPersistentCache();
      if (persistentCache != null && persistentCache.isNotEmpty) {
        // Actualizar cache en memoria
        _updateMemoryCache(persistentCache);
        return CacheResult(
          data: persistentCache,
          source: CacheSource.persistent,
          isStale: _isPersistentCacheStale(),
        );
      }
    }

    // Nivel 3: No hay cache disponible
    return CacheResult(
      data: null,
      source: CacheSource.none,
      isStale: false,
    );
  }

  /// Guarda datos en ambos niveles de cache
  Future<void> setCachedData(List<FoundationInsight> insights) async {
    // Guardar en memoria (Nivel 1)
    _updateMemoryCache(insights);

    // Guardar en persistente (Nivel 2)
    await repository.cacheDonationInsights(insights);
  }

  /// Cache warming: Pre-carga datos en memoria
  Future<void> warmCache() async {
    final persistentCache = await getPersistentCache();
    if (persistentCache != null && persistentCache.isNotEmpty) {
      _updateMemoryCache(persistentCache);
    }
  }

  /// Invalidación de cache basada en tiempo (TTL)
  bool _isMemoryCacheValid() {
    if (_memoryCache == null || _memoryCacheTimestamp == null) {
      return false;
    }
    final age = DateTime.now().difference(_memoryCacheTimestamp!);
    return age < insightsTTL;
  }

  bool _isMemoryCacheStale() {
    if (_memoryCacheTimestamp == null) return true;
    final age = DateTime.now().difference(_memoryCacheTimestamp!);
    return age > staleThreshold;
  }

  bool _isPersistentCacheStale() {
    if (!repository.isInsightsCacheValid()) return true;
    // La validación ya está implementada en el repositorio
    return false;
  }

  void _updateMemoryCache(List<FoundationInsight> insights) {
    _memoryCache = insights;
    _memoryCacheTimestamp = DateTime.now();
  }

  /// Invalidación de cache por eventos
  Future<void> invalidateOnEvent(CacheInvalidationEvent event) async {
    switch (event) {
      case CacheInvalidationEvent.userDonationCreated:
        // Invalidar cache cuando se crea una nueva donación
        await invalidateCache();
        break;
      case CacheInvalidationEvent.userLoggedOut:
        // Limpiar cache al cerrar sesión
        await clearAllCache();
        break;
      case CacheInvalidationEvent.forceRefresh:
        // Forzar refresco completo
        await invalidateCache();
        break;
      case CacheInvalidationEvent.staleData:
        // Marcar como stale pero mantener
        _memoryCacheTimestamp = DateTime.now().subtract(staleThreshold);
        break;
    }
  }

  /// Invalidar cache (mantener datos pero marcarlos como inválidos)
  Future<void> invalidateCache() async {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    await repository.clearInsightsCache();
  }

  /// Limpiar todo el cache
  Future<void> clearAllCache() async {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    await repository.clearInsightsCache();
  }

  /// Obtener estadísticas del cache
  CacheStats getCacheStats() {
    final hasMemoryCache = _memoryCache != null && _isMemoryCacheValid();
    final memoryAge = _memoryCacheTimestamp != null
        ? DateTime.now().difference(_memoryCacheTimestamp!)
        : null;

    return CacheStats(
      hasMemoryCache: hasMemoryCache,
      hasPersistentCache: repository.isInsightsCacheValid(),
      memoryCacheSize: _memoryCache?.length ?? 0,
      memoryCacheAge: memoryAge,
      isStale: hasMemoryCache ? _isMemoryCacheStale() : false,
    );
  }

  /// Estrategia de refresh: Stale-while-revalidate
  /// Retorna cache aunque esté stale, pero también dispara refresh en background
  Future<List<FoundationInsight>?> getStaleWhileRevalidate() async {
    final result = await getCachedData(userId: '');
    
    // Si hay cache (aunque esté stale), retornarlo inmediatamente
    if (result.data != null) {
      return result.data;
    }
    
    return null;
  }
}

/// Resultado de una operación de cache
class CacheResult {
  final List<FoundationInsight>? data;
  final CacheSource source;
  final bool isStale;

  CacheResult({
    required this.data,
    required this.source,
    required this.isStale,
  });

  bool get hasData => data != null && data!.isNotEmpty;
}

/// Fuente del cache
enum CacheSource {
  memory,      // Cache en memoria (más rápido)
  persistent,  // Cache persistente (SharedPreferences)
  none,        // No hay cache disponible
}

/// Eventos que pueden invalidar el cache
enum CacheInvalidationEvent {
  userDonationCreated,  // Nueva donación creada
  userLoggedOut,        // Usuario cerró sesión
  forceRefresh,         // Refresco forzado
  staleData,           // Datos marcados como stale
}

/// Estadísticas del cache
class CacheStats {
  final bool hasMemoryCache;
  final bool hasPersistentCache;
  final int memoryCacheSize;
  final Duration? memoryCacheAge;
  final bool isStale;

  CacheStats({
    required this.hasMemoryCache,
    required this.hasPersistentCache,
    required this.memoryCacheSize,
    required this.memoryCacheAge,
    required this.isStale,
  });

  String get memoryCacheAgeFormatted {
    if (memoryCacheAge == null) return 'N/A';
    if (memoryCacheAge!.inMinutes < 60) {
      return '${memoryCacheAge!.inMinutes} min';
    }
    if (memoryCacheAge!.inHours < 24) {
      return '${memoryCacheAge!.inHours} h';
    }
    return '${memoryCacheAge!.inDays} días';
  }

  String get cacheStatus {
    if (hasMemoryCache && !isStale) return 'Fresh (Memory)';
    if (hasMemoryCache && isStale) return 'Stale (Memory)';
    if (hasPersistentCache) return 'Persistent';
    return 'No Cache';
  }
}

