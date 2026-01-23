import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;
  List<String> _labels = [];

  // Set a threshold (e.g., 0.40) to ignore low-confidence results
  final double threshold = 0.35;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_quantized.tflite',
      );

      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
    } catch (e) {
      print("Error loading model or labels: $e");
    }
  }

  Future<List<Map<String, dynamic>>> predictFromBytes(Uint8List bytes) async {
    // Memory fix: decode the image while being mindful of large file sizes
    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) return [];

    // Preprocess to [1, 224, 224, 3] uint8 tensor
    final inputTensor = _preprocessImage(rawImage);

    // Prepare output buffer for INT8 quantization (uint8)
    var output =
        List<int>.filled(_labels.length, 0).reshape([1, _labels.length]);

    try {
      _interpreter.run(inputTensor, output);
    } catch (e) {
      print("Interpreter error: $e");
      return [];
    }

    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < _labels.length; i++) {
      double confidence = output[0][i] / 255.0;

      // Only add results that meet the minimum confidence threshold
      if (confidence >= threshold) {
        results.add({
          'label': _labels[i].trim(),
          'confidence': confidence,
        });
      }
    }

    // Sort by highest confidence
    results.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    // If no results met the threshold, return a generic "Uncertain" map
    if (results.isEmpty) {
      return [
        {'label': 'Uncertain / Low Confidence', 'confidence': 0.0}
      ];
    }

    return results.take(3).toList();
  }

  List<dynamic> _preprocessImage(img.Image image) {
    // 1. CENTER CROP: Prevents leaf distortion (Matches Python target_size)
    int size = image.width < image.height ? image.width : image.height;
    int xOffset = (image.width - size) ~/ 2;
    int yOffset = (image.height - size) ~/ 2;

    final cropped = img.copyCrop(
      image,
      x: xOffset,
      y: yOffset,
      width: size,
      height: size,
    );

    // 2. RESIZE: To exactly what the model was trained on
    final resized = img.copyResize(cropped, width: 224, height: 224);

    // 3. PIXEL MAPPING: Ensure RGB order
    // MobileNetV2 is highly sensitive to color channels.
    return List.generate(
      1,
      (b) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) => List.generate(3, (c) {
            final pixel = resized.getPixel(x, y);

            // Using .toInt() because the model is INT8 Quantized
            // c=0 is Red, c=1 is Green, c=2 is Blue
            if (c == 0) return pixel.r.toInt();
            if (c == 1) return pixel.g.toInt();
            return pixel.b.toInt();
          }),
        ),
      ),
    );
  }

  void close() {
    _interpreter.close();
  }
}
