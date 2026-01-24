import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import '../ml/tflite_service.dart';
import '../services/database_helper.dart'; // Ensure you have this file
import 'result_screen.dart';
import '../main.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final tflite = TFLiteService();
  final ImagePicker _picker = ImagePicker();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await tflite.loadModel();
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    tflite.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processImage(File(pickedFile.path));
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy)
      return;

    try {
      final XFile file = await _controller!.takePicture();
      _processImage(File(file.path));
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  Future<void> _processImage(File file) async {
    setState(() => _isBusy = true);
    try {
      final bytes = await file.readAsBytes();
      final results = await tflite.predictFromBytes(bytes);

      if (results.isNotEmpty && results[0]['confidence'] > 0.1) {
        // --- DATA STORAGE UPDATE ---
        await DatabaseHelper.instance.insertScan({
          'label': results[0]['label'],
          'confidence': results[0]['confidence'],
          'date': DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
          'imagePath': file.path,
        });
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(image: file, results: results),
        ),
      );
    } catch (e) {
      debugPrint("Processing error: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'gallery_btn',
                onPressed: _isBusy ? null : _pickImage,
                backgroundColor: Colors.white,
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              GestureDetector(
                onTap: _isBusy ? null : _captureImage,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.camera_alt, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ),
        if (_isBusy)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 10),
                  Text("Analyzing Leaf...",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
