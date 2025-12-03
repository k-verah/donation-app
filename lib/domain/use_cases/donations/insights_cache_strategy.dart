import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';


class InsightsCacheStrategy {
  final LocalStorageRepository repository;

  InsightsCacheStrategy(this.repository);


  static const Duration insightsTTL = Duration(hours: 24);
  static const Duration staleThreshold = Duration(hours: 12);
  static const Duration maxAge = Duration(days: 7);


  List<FoundationInsight>? _memoryCache;
  DateTime? _memoryCacheTimestamp;


  Future<List<FoundationInsight>?> getPersistentCache() async {
    final cached = repository.getCachedDonationInsights();
    if (cached != null && repository.isInsightsCacheValid()) {
      return cached;
    }
    return null;
  }


  Future<CacheResult> getCachedData({
    required String userId,
    bool forceRefresh = false,
  }) async {

    if (!forceRefresh && _isMemoryCacheValid()) {
      return CacheResult(
        data: _memoryCache!,
        source: CacheSource.memory,
        isStale: _isMemoryCacheStale(),
      );
    }


    if (!forceRefresh) {
      final persistentCache = await getPersistentCache();
      if (persistentCache != null && persistentCache.isNotEmpty) {

        _updateMemoryCache(persistentCache);
        return CacheResult(
          data: persistentCache,
          source: CacheSource.persistent,
          isStale: _isPersistentCacheStale(),
        );
      }
    }


    return CacheResult(
      data: null,
      source: CacheSource.none,
      isStale: false,
    );
  }


  Future<void> setCachedData(List<FoundationInsight> insights) async {

    _updateMemoryCache(insights);


    await repository.cacheDonationInsights(insights);
  }


  Future<void> warmCache() async {
    final persistentCache = await getPersistentCache();
    if (persistentCache != null && persistentCache.isNotEmpty) {
      _updateMemoryCache(persistentCache);
    }
  }


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

    return false;
  }

  void _updateMemoryCache(List<FoundationInsight> insights) {
    _memoryCache = insights;
    _memoryCacheTimestamp = DateTime.now();
  }


  Future<void> invalidateOnEvent(CacheInvalidationEvent event) async {
    switch (event) {
      case CacheInvalidationEvent.userDonationCreated:

        await invalidateCache();
        break;
      case CacheInvalidationEvent.userLoggedOut:

        await clearAllCache();
        break;
      case CacheInvalidationEvent.forceRefresh:

        await invalidateCache();
        break;
      case CacheInvalidationEvent.staleData:

        _memoryCacheTimestamp = DateTime.now().subtract(staleThreshold);
        break;
    }
  }


  Future<void> invalidateCache() async {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    await repository.clearInsightsCache();
  }


  Future<void> clearAllCache() async {
    _memoryCache = null;
    _memoryCacheTimestamp = null;
    await repository.clearInsightsCache();
  }


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



  Future<List<FoundationInsight>?> getStaleWhileRevalidate() async {
    final result = await getCachedData(userId: '');
    

    if (result.data != null) {
      return result.data;
    }
    
    return null;
  }
}


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


enum CacheSource {
  memory,      
  persistent,  
  none,        
}


enum CacheInvalidationEvent {
  userDonationCreated,  
  userLoggedOut,        
  forceRefresh,         
  staleData,           
}


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

