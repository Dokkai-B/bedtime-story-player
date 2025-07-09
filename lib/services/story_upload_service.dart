import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class StoryUploadService {
  // Backend URL - Uses centralized configuration
  static String get baseUrl => AppConfig.baseUrl;
  
  /// Upload a file to the backend
  /// Returns a Map with upload details including S3 location
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'story', // This must match the field name expected by your backend
          file.path,
        ),
      );

      // Add headers if needed
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });

      // Send the request
      var streamedResponse = await request.send();
      
      // Get the response
      var response = await http.Response.fromStream(streamedResponse);
      
      // Parse the JSON response
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Success - return the upload data
        return responseData['data'] as Map<String, dynamic>;
      } else {
        // Error - throw exception with server error message
        throw Exception(responseData['message'] ?? 'Upload failed');
      }
      
    } catch (e) {
      // Handle network or other errors
      if (e is SocketException) {
        throw Exception('Cannot connect to server. Make sure your backend is running on $baseUrl');
      } else if (e is FormatException) {
        throw Exception('Invalid response from server');
      } else {
        throw Exception('Upload error: ${e.toString()}');
      }
    }
  }

  /// Check if the backend server is healthy
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'OK';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get list of uploaded stories (when backend implements this)
  Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // This will need to be updated when you implement the stories endpoint
        return [];
      } else {
        throw Exception('Failed to fetch stories');
      }
    } catch (e) {
      throw Exception('Error fetching stories: ${e.toString()}');
    }
  }
}

/// Model class for upload response
class UploadResult {
  final String fileName;
  final int fileSize;
  final String fileType;
  final String s3Key;
  final String s3Location;
  final DateTime uploadedAt;
  final bool testMode;

  UploadResult({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.s3Key,
    required this.s3Location,
    required this.uploadedAt,
    this.testMode = false,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      fileType: json['fileType'] ?? '',
      s3Key: json['s3Key'] ?? '',
      s3Location: json['s3Location'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      testMode: json['testMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      's3Key': s3Key,
      's3Location': s3Location,
      'uploadedAt': uploadedAt.toIso8601String(),
      'testMode': testMode,
    };
  }
}
