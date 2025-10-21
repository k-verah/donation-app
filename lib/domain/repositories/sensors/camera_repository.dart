import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

abstract class CameraRepository {
  Future<void> initBackCamera();
  Future<XFile> takePicture();
  Future<XFile?> pickFromGallery();
  Future<void> dispose();
  CameraController? get controller;
}
