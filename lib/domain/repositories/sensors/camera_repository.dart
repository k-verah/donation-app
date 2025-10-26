import 'package:camera/camera.dart';

abstract class CameraRepository {
  Future<void> initBackCamera();
  Future<XFile> takePicture();
  Future<XFile?> pickFromGallery();
  Future<void> dispose();
  CameraController? get controller;
}
