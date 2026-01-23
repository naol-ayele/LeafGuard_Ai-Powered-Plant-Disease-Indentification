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


