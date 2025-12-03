import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';
import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';



class ManageInsightsStorage {
  final LocalStorageRepository repository;

  ManageInsightsStorage(this.repository);


  int getStorageSize() {
    final cached = repository.getCachedDonationInsights();
    if (cached == null) return 0;
    

    return cached.length * 200;
  }


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



  Future<bool> cleanupIfNeeded({
    int maxAgeInDays = 7,
    int maxSizeInBytes = 100000, // 100KB
  }) async {
    final info = getStorageInfo();
    

    if (!info.isValid || info.sizeInBytes > maxSizeInBytes) {
      await _clearCache();
      return true;
    }
    
    return false;
  }


  Future<void> _clearCache() async {
    await repository.clearInsightsCache();
  }


  Future<void> cleanupOldData({int keepLastDays = 3}) async {
    final cached = repository.getCachedDonationInsights();
    if (cached == null || cached.isEmpty) return;
    

    if (!repository.isInsightsCacheValid()) {
      await repository.clearInsightsCache();
      return;
    }
    
    


  }


  Future<void> optimizeStorage() async {
    final cached = repository.getCachedDonationInsights();
    if (cached == null || cached.isEmpty) return;
    

    final uniqueInsights = <String, FoundationInsight>{};
    for (final insight in cached) {
      final key = insight.foundation.id;
      if (!uniqueInsights.containsKey(key) || 
          uniqueInsights[key]!.donationCount < insight.donationCount) {
        uniqueInsights[key] = insight;
      }
    }
    

    if (uniqueInsights.length < cached.length) {
      await repository.cacheDonationInsights(uniqueInsights.values.toList());
    }
  }


  bool verifyDataIntegrity() {
    final cached = repository.getCachedDonationInsights();
    if (cached == null) return true;
    

    for (final insight in cached) {
      if (insight.foundation.id.isEmpty ||
          insight.donationCount < 0 ||
          insight.averageDistance < 0) {
        return false;
      }
    }
    
    return true;
  }


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

