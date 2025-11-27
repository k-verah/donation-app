import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';

class StartCamera {
  final CameraRepository repo;
  StartCamera(this.repo);

  Future<void> call() => repo.initBackCamera();
}
