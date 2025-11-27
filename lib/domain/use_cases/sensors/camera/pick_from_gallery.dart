import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';
import 'package:image_picker/image_picker.dart';

class PickFromGallery {
  final CameraRepository repo;
  PickFromGallery(this.repo);

  Future<XFile?> call() => repo.pickFromGallery();
}
