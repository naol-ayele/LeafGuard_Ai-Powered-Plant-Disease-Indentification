import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leafguard/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service_test.mocks.dart';

@GenerateMocks([http.Client]) // Mock the Client, not the AuthService
void main() {
  late AuthService authService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    authService =
        AuthService(client: mockClient); // Inject mock into real service
    SharedPreferences.setMockInitialValues(
        {}); // Initialize SharedPreferences for testing
  });

  group('AuthService - Registration', () {
    test('Successful registration returns success true', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('{"success": true}', 200));

      final result =
          await authService.register('John', 'test@test.com', 'password123');

      expect(result['success'], true);
    });

    test('Registration fails with error message from server', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
              '{"success": false, "error": "Email exists"}', 400));

      final result =
          await authService.register('John', 'test@test.com', 'password123');

      expect(result['success'], false);
      expect(result['error'], 'Email exists');
    });

    test('Registration handles socket/network exception', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenThrow(Exception('No Internet'));

      final result =
          await authService.register('John', 'test@test.com', 'password123');

      expect(result['success'], false);
      expect(result['error'], contains('Exception: No Internet'));
    });
  });

  group('AuthService - Login', () {
    test('Successful login saves token and user data to SharedPreferences',
        () async {
      final responseBody = jsonEncode({
        'success': true,
        'token': 'fake_jwt_token',
        'user': {'name': 'John Doe', 'email': 'john@test.com'}
      });

      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await authService.login('john@test.com', 'password123');
      final prefs = await SharedPreferences.getInstance();

      expect(result['success'], true);
      expect(prefs.getString('token'), 'fake_jwt_token');
      expect(prefs.getString('userName'), 'John Doe');
    });

    test('Login handles invalid JSON or server error', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Invalid JSON', 500));

      final result = await authService.login('john@test.com', 'password123');

      expect(result['success'], false);
      expect(result['error'], 'Server communication error');
    });
  });

  group('AuthService - Change Password', () {
    test('changePassword returns error if token is missing', () async {
      final result = await authService.changePassword('old123', 'new123');
      expect(result['success'], false);
      expect(result['error'], 'auth_token_missing');
    });

    test('changePassword success with valid token', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'valid_token');

      when(mockClient.put(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async =>
              http.Response('{"success": true, "message": "Updated"}', 200));

      final result = await authService.changePassword('old123', 'new123');

      expect(result['success'], true);
      expect(result['message'], 'Updated');
    });
  });

  group('AuthService - Forgot/Reset Password', () {
    test('forgotPassword handles success response', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async =>
              http.Response('{"success": true, "message": "Email sent"}', 200));

      final result = await authService.forgotPassword('test@test.com');
      expect(result['success'], true);
    });

    test('resetPassword handles failure response', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
              '{"success": false, "error": "Invalid token"}', 400));

      final result = await authService.resetPassword('bad_token', 'new_pass');
      expect(result['success'], false);
      expect(result['error'], 'Invalid token');
    });
  });

  group('AuthService - Logout', () {
    test('logout clears SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'active_token');
      await prefs.setString('userName', 'John');

      await authService.logout();

      expect(prefs.getString('token'), isNull);
      expect(prefs.getString('userName'), isNull);
    });
  });
}
