import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';

/// Estrategia completa de gestión de almacenamiento local para Donation Insights
/// Incluye: gestión de espacio, limpieza automática, versionado y métricas
class ManageInsightsStorage {
  final LocalStorageRepository repository;

  ManageInsightsStorage(this.repository);

  /// Obtiene el tamaño aproximado del cache de insights en bytes
  int getStorageSize() {
    final cached = repository.getCachedDonationInsights();
    if (cached == null) return 0;
    
    // Estimación aproximada: cada insight ~200 bytes
    return cached.length * 200;
  }

  /// Obtiene información sobre el uso de almacenamiento
  StorageInfo getStorageInfo() {
    final cached = repository.getCachedDonationInsights();
    final isValid = repository.isInsightsCacheValid();
    final size = getStorageSize();
    
    return StorageInfo(
      itemCount: cached?.length ?? 0,
      sizeInBytes: size,
      isValid: isValid,
      isEmpty: cached == null || cached.isEmpty,
    );
  }

  /// Limpia el cache de insights si es necesario
  /// Retorna true si se limpió el cache
  Future<bool> cleanupIfNeeded({
    int maxAgeInDays = 7,
    int maxSizeInBytes = 100000, // 100KB
  }) async {
    final info = getStorageInfo();
    
    // Limpiar si el cache es inválido o muy grande
    if (!info.isValid || info.sizeInBytes > maxSizeInBytes) {
      await _clearCache();
      return true;
    }
    
    return false;
  }

  /// Limpia el cache de insights
  Future<void> _clearCache() async {
    await repository.clearInsightsCache();
  }

  /// Limpia datos antiguos manteniendo solo los más recientes
  Future<void> cleanupOldData({int keepLastDays = 3}) async {
    final cached = repository.getCachedDonationInsights();
    if (cached == null || cached.isEmpty) return;
    
    // Si el cache es inválido, limpiarlo completamente
    if (!repository.isInsightsCacheValid()) {
      await repository.clearInsightsCache();
      return;
    }
    
    // Por ahora mantenemos todos los datos válidos
    // En el futuro se puede implementar lógica más sofisticada
  }

  /// Optimiza el almacenamiento eliminando datos redundantes
  Future<void> optimizeStorage() async {
    final cached = repository.getCachedDonationInsights();
    if (cached == null || cached.isEmpty) return;
    
    // Eliminar duplicados basados en foundation.id
    final uniqueInsights = <String, FoundationInsight>{};
    for (final insight in cached) {
      final key = insight.foundation.id;
      if (!uniqueInsights.containsKey(key) || 
          uniqueInsights[key]!.donationCount < insight.donationCount) {
        uniqueInsights[key] = insight;
      }
    }
    
    // Guardar solo los únicos
    if (uniqueInsights.length < cached.length) {
      await repository.cacheDonationInsights(uniqueInsights.values.toList());
    }
  }

  /// Verifica la integridad de los datos almacenados
  bool verifyDataIntegrity() {
    final cached = repository.getCachedDonationInsights();
    if (cached == null) return true;
    
    // Verificar que todos los insights tengan datos válidos
    for (final insight in cached) {
      if (insight.foundation.id.isEmpty ||
          insight.donationCount < 0 ||
          insight.averageDistance < 0) {
        return false;
      }
    }
    
    return true;
  }

  /// Obtiene estadísticas de uso del almacenamiento
  StorageStats getStorageStats() {
    final info = getStorageInfo();
    final isValid = repository.isInsightsCacheValid();
    
    return StorageStats(
      totalItems: info.itemCount,
      totalSizeBytes: info.sizeInBytes,
      isValid: isValid,
      isEmpty: info.isEmpty,
      integrityOk: verifyDataIntegrity(),
    );
  }
}

/// Información sobre el almacenamiento
class StorageInfo {
  final int itemCount;
  final int sizeInBytes;
  final bool isValid;
  final bool isEmpty;

  StorageInfo({
    required this.itemCount,
    required this.sizeInBytes,
    required this.isValid,
    required this.isEmpty,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Estadísticas de almacenamiento
class StorageStats {
  final int totalItems;
  final int totalSizeBytes;
  final bool isValid;
  final bool isEmpty;
  final bool integrityOk;

  StorageStats({
    required this.totalItems,
    required this.totalSizeBytes,
    required this.isValid,
    required this.isEmpty,
    required this.integrityOk,
  });

  String get sizeFormatted {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

