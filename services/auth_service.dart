import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  static const String baseUrl =
      "https://subterraqueous-janis-heterothallic.ngrok-free.dev/api/auth";

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Something went wrong'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Server communication error'};
    }
  }