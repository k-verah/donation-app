import 'package:camera/camera.dart';
import 'package:donation_app/data/datasources/sensors/camera_datasource.dart';
import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';

class CameraRepositoryImpl implements CameraRepository {
  final CameraDatasource _ds;
  CameraRepositoryImpl(this._ds);

  @override
  Future<void> initBackCamera() => _ds.initBackCamera();

  @override
  Future<XFile> takePicture() => _ds.takePicture();

  @override
  Future<XFile?> pickFromGallery() => _ds.pickFromGallery();

  @override
  CameraController? get controller => _ds.controller;

  @override
  Future<void> dispose() => _ds.dispose();
}
