import 'package:camera/camera.dart';
import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';

class TakePhoto {
  final CameraRepository repo;
  TakePhoto(this.repo);

  Future<XFile> call() => repo.takePicture();
}
