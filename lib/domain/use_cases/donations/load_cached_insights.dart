import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class LoadCachedInsights {
  final LocalStorageRepository repository;

  LoadCachedInsights(this.repository);

  List<FoundationInsight>? call() {
    final cached = repository.getCachedDonationInsights();
    if (cached != null && repository.isInsightsCacheValid()) {
      return cached;
    }
    return null;
  }
}
