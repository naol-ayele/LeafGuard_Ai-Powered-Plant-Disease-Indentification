<<<<<<< HEAD

=======
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
<<<<<<< HEAD

class ApiService {
  // Use your computer's IP address if testing on a real device
=======
class ApiService {
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
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
<<<<<<< HEAD
    required String token, // Required for your authMiddleware
=======
    required String token, 
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/scans/upload");
      var request = http.MultipartRequest('POST', uri);

<<<<<<< HEAD
      // 1. Add Auth Header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // 2. Add File
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', // Must match req.file name in Node.js
=======
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', 
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
        stream,
        length,
        filename: basename(imageFile.path),
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

<<<<<<< HEAD
      // 3. Add Fields (Must match your scanController.js destructuring)
=======
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
      request.fields['label'] = label;
      request.fields['confidence'] = confidence.toString();
      request.fields['status'] = status;
      request.fields['plant'] = plant;
      request.fields['cause'] = cause;
      request.fields['symptoms'] = symptoms;
      request.fields['treatment'] = treatment;

<<<<<<< HEAD
      // 4. Send and Handle Response
=======
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 33d616d49c6a31fd14fcb031575f8c27363fa6dd
