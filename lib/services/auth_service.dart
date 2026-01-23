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
  // Register User
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }
  // Login User and Save Token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

