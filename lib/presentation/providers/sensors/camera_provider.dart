import 'package:camera/camera.dart';
import 'package:donation_app/domain/repositories/sensors/camera_repository.dart';
import 'package:donation_app/domain/use_cases/sensors/camera/pick_from_gallery.dart';
import 'package:donation_app/domain/use_cases/sensors/camera/start_camera.dart';
import 'package:donation_app/domain/use_cases/sensors/camera/stop_camera.dart';
import 'package:donation_app/domain/use_cases/sensors/camera/take_photo.dart';
import 'package:flutter/material.dart';

class CameraProvider extends ChangeNotifier {
  final CameraRepository _repo;
  final StartCamera _startCamera;
  final TakePhoto _takePhoto;
  final StopCamera _stopCamera;
  final PickFromGallery _pickFromGallery;

  bool _loading = false;
  XFile? _lastShot;

  CameraProvider({
    required CameraRepository repo,
    required StartCamera startCamera,
    required TakePhoto takePhoto,
    required StopCamera stopCamera,
    required PickFromGallery pickFromGallery,
  })  : _repo = repo,
        _startCamera = startCamera,
        _takePhoto = takePhoto,
        _stopCamera = stopCamera,
        _pickFromGallery = pickFromGallery;

  bool get loading => _loading;
  XFile? get lastShot => _lastShot;
  CameraController? get controller => _repo.controller;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      await _startCamera();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<XFile?> shoot() async {
    final file = await _takePhoto();
    _lastShot = file;
    notifyListeners();
    return file;
  }

  Future<XFile?> pickGallery() async {
    final img = await _pickFromGallery();
    _lastShot = img;
    notifyListeners();
    return img;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }
}
