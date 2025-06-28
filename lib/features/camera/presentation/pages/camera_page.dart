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

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isPermissionGranted = false;
  Future<void>? _initCameraControllerFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("[CameraPage] App lifecycle state changed to: $state");

    if (state == AppLifecycleState.resumed) {
      debugPrint("[CameraPage] App has resumed. Checking status without requesting.");
      _checkPermissionsOnResume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_controller != null) {
        debugPrint("[CameraPage] App is not active. Disposing camera controller.");
        _controller!.dispose();
        if (mounted) {
          setState(() {
            _initCameraControllerFuture = null;
            _controller = null;
          });
        }
      }
    }
  }

  Future<void> _requestPermissionsOnLaunch() async {
    debugPrint("[CameraPage] Requesting initial permissions...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    debugPrint("[CameraPage] Camera status: ${statuses[Permission.camera]}");

    if (statuses[Permission.camera] == PermissionStatus.granted) {
      debugPrint("[CameraPage] Permission granted on launch. Initializing camera.");
      if (mounted) {
        setState(() {
          _isPermissionGranted = true;
        });
        _initializeCamera();
      }
    } else {
      debugPrint("[CameraPage] Permission denied on launch.");
      if (mounted) {
        setState(() {
          _isPermissionGranted = false;
        });
      }
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    debugPrint("[CameraPage] Checking status on resume...");
    final status = await Permission.camera.status;
    debugPrint("[CameraPage] Status on resume: $status");

    if (status == PermissionStatus.granted && !_isPermissionGranted) {
      debugPrint("[CameraPage] Permission was granted in settings. Initializing camera.");
      if (mounted) {
        setState(() {
          _isPermissionGranted = true;
        });
        _initializeCamera();
      }
    } else {
      debugPrint("[CameraPage] Permission still not granted.");
    }
  }

  Future<void> _openPermissionSettings() async {
    debugPrint("[CameraPage] 'Open Settings' button tapped. Calling openAppSettings().");
    await openAppSettings();
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To capture your epic TTRPG moments, CritChat needs access to your camera. Please grant permission in your device settings.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _openPermissionSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
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