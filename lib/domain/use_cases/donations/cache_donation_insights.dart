import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class CacheDonationInsights {
  final LocalStorageRepository repository;

  CacheDonationInsights(this.repository);

  Future<void> call(List<FoundationInsight> insights) async {
    await repository.cacheDonationInsights(insights);
  }
}
