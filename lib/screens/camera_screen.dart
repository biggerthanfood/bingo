import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraScreen extends StatefulWidget {
  final Function(String) onPhotoTaken;

  const CameraScreen({
    super.key,
    required this.onPhotoTaken,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _showError('No cameras found');
        return;
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) {
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      await Gal.putImage(photo.path);
      
      final directory = await getTemporaryDirectory();
      final String fileName = path.basename(photo.path);
      final String filePath = path.join(directory.path, fileName);
      
      widget.onPhotoTaken(filePath);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error taking picture: $e');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.camera_circle_fill,
                      color: Colors.white,
                      size: 60,
                    ),
                    onPressed: _takePicture,
                  ),
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.camera_rotate,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () async {
                      final cameras = _cameras;
                      if (cameras.length > 1) {
                        final currentIndex = cameras.indexOf(_controller!.description);
                        final nextIndex = (currentIndex + 1) % cameras.length;
                        await _controller?.dispose();
                        _controller = CameraController(
                          cameras[nextIndex],
                          ResolutionPreset.high,
                          enableAudio: false,
                        );
                        await _controller!.initialize();
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}