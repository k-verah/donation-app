import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensors/camera_provider.dart';

class CameraSensorScreen extends StatefulWidget {
  const CameraSensorScreen({super.key});

  @override
  State<CameraSensorScreen> createState() => _CameraSensorScreenState();
}

class _CameraSensorScreenState extends State<CameraSensorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().init();
    });
  }

  Future<void> _shoot() async {
    final shot = await context.read<CameraProvider>().shoot();
    if (!mounted) return;
    if (shot != null) Navigator.pop(context, shot);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CameraProvider>();
    final ctrl = prov.controller;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: prov.loading || ctrl == null || !ctrl.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: ctrl.value.previewSize!.height,
                      height: ctrl.value.previewSize!.width,
                      child: CameraPreview(ctrl),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: ElevatedButton.icon(
                      onPressed: _shoot,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
