import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class LoadFilterPreferences {
  final LocalStorageRepository repository;

  LoadFilterPreferences(this.repository);

  Map<String, String> call() {
    return repository.getFilterPreferences();
  }
}