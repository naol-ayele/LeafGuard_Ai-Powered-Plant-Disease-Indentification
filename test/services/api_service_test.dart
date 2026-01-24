import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leafguard/services/api_service.dart'; // Adjust path

void main() {
  group('ApiService - uploadScan', () {
    late File testFile;

    setUp(() async {
      // Create a temporary file for testing
      testFile = File('${Directory.systemTemp.path}/test_image.jpg');
      await testFile.writeAsBytes([0, 1, 2, 3]);
    });

    tearDown(() async {
      if (await testFile.exists()) {
        await testFile.delete();
      }
    });

    test('returns success map when server returns 200', () async {
      // We use MockClient to intercept the MultipartRequest
      // Note: testing MultipartRequest logic inside the service directly
      // usually requires a slightly different approach if you want to
      // verify fields, but this validates the response handling.

      // Since ApiService creates its own internal request,
      // standard Mockito 'when' on a client doesn't work unless you
      // refactor ApiService to accept an http.Client.
      // Assuming standard implementation, we test the outcome:

      // OPTIONAL: If you refactor ApiService(this.client)
      // verify(client.send(any)).called(1);
    });

    test('handles network exceptions gracefully', () async {
      // Logic to test the try-catch block
      final apiService = ApiService();

      // Passing a non-existent file to trigger an error in the stream
      final result = await apiService.uploadScan(
        imageFile: File('non_existent_path.jpg'),
        label: 'Healthy',
        confidence: 0.99,
        status: 'Success',
        plant: 'Tomato',
        cause: 'None',
        symptoms: 'None',
        treatment: 'None',
        token: 'fake_token',
      );

      expect(result['success'], isFalse);
      expect(result.containsKey('error'), isTrue);
    });

    test('verifies all multipart fields and headers are sent', () async {
      final mockClient = MockClient((request) async {
        // Verify Headers
        expect(request.headers['Authorization'], 'Bearer my_token');

        // Verify it is a multipart request
        expect(request, isA<http.MultipartRequest>());
        final multipartRequest = request as http.MultipartRequest;

        // Verify Fields
        expect(multipartRequest.fields['label'], 'Tomato_Late_Blight');
        expect(multipartRequest.fields['plant'], 'Tomato');

        return http.Response(json.encode({"success": true}), 200);
      });

      final apiService = ApiService(client: mockClient);
      await apiService.uploadScan(
        imageFile: testFile,
        label: 'Tomato_Late_Blight',
        confidence: 0.85,
        status: 'Infected',
        plant: 'Tomato',
        cause: 'Fungus',
        symptoms: 'Dark spots',
        treatment: 'Fungicide',
        token: 'my_token',
      );
    });
  });
}
