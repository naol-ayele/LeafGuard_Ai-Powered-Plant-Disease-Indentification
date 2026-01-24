// test/fakes/fake_tflite_service.dart
import 'dart:typed_data';
import 'package:leafguard/ml/tflite_service.dart';

class FakeTFLiteService extends TFLiteService {
  @override
  Future<void> loadModel() async {
    // Simulate successful model loading
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<Map<String, dynamic>>> predictFromBytes(Uint8List bytes) async {
    // Return fake results for testing
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'label': 'Tomato___healthy', 'confidence': 0.95},
      {'label': 'Tomato___Early_blight', 'confidence': 0.05},
    ];
  }

  @override
  void close() {
    // No-op for fake service
  }
}
