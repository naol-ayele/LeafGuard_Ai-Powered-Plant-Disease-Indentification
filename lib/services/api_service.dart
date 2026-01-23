import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
class ApiService {
  // Use your computer's IP address if testing on a real device
  static const String baseUrl =
      "https://subterraqueous-janis-heterothallic.ngrok-free.dev/api";
Future<Map<String, dynamic>> uploadScan({
    required File imageFile,
    required String label,
    required double confidence,
    required String status,
    required String plant,
    required String cause,
    required String symptoms,
    required String treatment,
    required String token, // Required for your authMiddleware
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/scans/upload");
      var request = http.MultipartRequest('POST', uri);
      // 1. Add Auth Header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true'
      // 2. Add File
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', // Must match req.file name in Node.js
        stream,
        length,
        filename: basename(imageFile.path),
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      // 3. Add Fields (Must match your scanController.js destructuring)
      request.fields['label'] = label;
      request.fields['confidence'] = confidence.toString();
      request.fields['status'] = status;
      request.fields['plant'] = plant;
      request.fields['cause'] = cause;
      request.fields['symptoms'] = symptoms;
      request.fields['treatment'] = treatment;


