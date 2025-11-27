import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';

class StopCamera {
  final CameraRepository repo;
  StopCamera(this.repo);

  Future<void> call() => repo.dispose();
}
