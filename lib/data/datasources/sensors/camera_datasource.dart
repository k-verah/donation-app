import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraDatasource {
  CameraController? _controller;
  final ImagePicker _picker = ImagePicker();

  CameraController? get controller => _controller;

  Future<void> initBackCamera({
    ResolutionPreset preset = ResolutionPreset.high,
    bool enableAudio = false,
    ImageFormatGroup format = ImageFormatGroup.yuv420,
  }) async {
    final cams = await availableCameras();
    if (cams.isEmpty) {
      throw CameraException('no_camera', 'No cameras available');
    }
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );

    _controller?.dispose();
    _controller = CameraController(
      back,
      preset,
      enableAudio: enableAudio,
      imageFormatGroup: format,
    );
    await _controller!.initialize();
  }

  Future<XFile> takePicture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }
    return c.takePicture();
  }

  Future<XFile?> pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    return img;
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
