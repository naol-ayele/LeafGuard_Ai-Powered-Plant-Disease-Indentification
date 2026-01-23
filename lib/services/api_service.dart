import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
class ApiService {
  // Use your computer's IP address if testing on a real device
  static const String baseUrl =
      "https://subterraqueous-janis-heterothallic.ngrok-free.dev/api";
