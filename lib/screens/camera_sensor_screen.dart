import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraSensorScreen extends StatefulWidget {
  const CameraSensorScreen({super.key});

  @override
  State<CameraSensorScreen> createState() => _CameraSensorScreenState();
}

class _CameraSensorScreenState extends State<CameraSensorScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    if (cams.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    _controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shoot() async {
    if (_controller == null) return;
    final file = await _controller!.takePicture();
    if (!mounted) return;
    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cámara'),
      ),
      body: (_controller == null)
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: _initFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final previewSize = _controller!.value.previewSize!;
                final w = previewSize.width;
                final h = previewSize.height;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: h,
                          height: w,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: ElevatedButton.icon(
                          onPressed: _shoot,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar foto'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
