import 'package:donation_app/domain/repositories/local/local_storage_repository.dart';

class SaveFilterPreferences {
  final LocalStorageRepository repository;

  SaveFilterPreferences(this.repository);

  Future<void> call({
    required String cause,
    required String access,
    required String schedule,
  }) async {
    await repository.saveFilterPreferences(
      cause: cause,
      access: access,
      schedule: schedule,
    );
  }
}