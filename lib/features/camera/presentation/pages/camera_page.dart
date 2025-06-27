import 'package:camera/camera.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/features/camera/presentation/pages/preview_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isPermissionGranted = false;
  Future<void>? _initCameraControllerFuture;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        _isPermissionGranted = true;
      });
      _initializeCamera();
    } else if (status == PermissionStatus.permanentlyDenied) {
      await openAppSettings();
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras?.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first);

    if (frontCamera != null) {
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false, // Videos will need audio
      );
      _initCameraControllerFuture = _controller?.initialize();
    }
    // `setState` is called to rebuild the widget with the controller.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera permission denied.'),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_controller == null || _initCameraControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initCameraControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return Stack(
            children: <Widget>[
              CameraPreview(_controller!),
              _buildControlsOverlay(),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppTopBar(backgroundColor: Colors.transparent),
              ),
            ],
          );
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildControlsOverlay() {
    return Stack(
      children: [
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: _buildCaptureButton(),
        ),
        Positioned(
          right: 20,
          bottom: 100,
          child: _buildSideButtons(),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _onTakePhotoPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _onTakePhotoPressed() async {
    try {
      await _initCameraControllerFuture;

      final image = await _controller!.takePicture();

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(filePath: image.path),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Widget _buildSideButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        _buildSideButton(Icons.casino_outlined, 'Dice'),
        const SizedBox(height: 20),
        _buildSideButton(Icons.border_all_rounded, 'Borders'),
        const SizedBox(height: 20),
        _buildSideButton(Icons.filter_vintage_outlined, 'Effects'),
      ],
    );
  }

  Widget _buildSideButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
} 