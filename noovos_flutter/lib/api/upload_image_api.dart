/*
Upload Image API Client
Handles uploading images to Cloudinary via the server API
Converts image files to base64 and sends them to the upload_image endpoint
*/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../helpers/config_helper.dart';
import '../helpers/auth_helper.dart';

class UploadImageApi {
  /*
  * Upload an image file to Cloudinary
  *
  * @param imageFile The image file to upload
  * @param folder Optional folder name for organization (default: 'general')
  * @return Map containing success status and response data
  */
  static Future<Map<String, dynamic>> uploadImage(
    File imageFile, {
    String folder = 'general',
  }) async {
    try {
      // Get the API base URL
      final baseUrl = await ConfigHelper.getApiBaseUrl();
      final url = Uri.parse('$baseUrl/upload_image');

      // Get authentication token
      final token = await AuthHelper.getToken();
      if (token == null) {
        return {
          'success': false,
          'return_code': 'NO_AUTH_TOKEN',
          'message': 'Authentication token not found'
        };
      }

      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      final String base64Image = base64Encode(imageBytes);

      // Create data URL format for better compatibility
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'image': dataUrl,
        'folder': folder,
      };

      // Make the API request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'return_code': responseData['return_code'],
          'image_url': responseData['image_url'],
          'public_id': responseData['public_id'],
          'image_name': responseData['image_name'],  // Added missing image_name field
          'width': responseData['width'],
          'height': responseData['height'],
          'file_size': responseData['file_size'],
          'cloudinary_bytes': responseData['cloudinary_bytes'],
        };
      } else {
        return {
          'success': false,
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
          'message': responseData['message'] ?? 'Upload failed'
        };
      }
    } catch (e) {
      // Handle any errors that occur during the request
      return {
        'success': false,
        'return_code': 'CLIENT_ERROR',
        'message': 'Failed to upload image: $e'
      };
    }
  }

  /*
  * Upload an image from bytes (useful for camera captures)
  *
  * @param imageBytes The image data as bytes
  * @param folder Optional folder name for organization (default: 'general')
  * @return Map containing success status and response data
  */
  static Future<Map<String, dynamic>> uploadImageFromBytes(
    Uint8List imageBytes, {
    String folder = 'general',
  }) async {
    try {
      // Get the API base URL
      final baseUrl = await ConfigHelper.getApiBaseUrl();
      final url = Uri.parse('$baseUrl/upload_image');

      // Get authentication token
      final token = await AuthHelper.getToken();
      if (token == null) {
        return {
          'success': false,
          'return_code': 'NO_AUTH_TOKEN',
          'message': 'Authentication token not found'
        };
      }

      // Convert to base64
      final String base64Image = base64Encode(imageBytes);

      // Create data URL format for better compatibility
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'image': dataUrl,
        'folder': folder,
      };

      // Make the API request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'return_code': responseData['return_code'],
          'image_url': responseData['image_url'],
          'public_id': responseData['public_id'],
          'image_name': responseData['image_name'],  // Added missing image_name field
          'width': responseData['width'],
          'height': responseData['height'],
          'file_size': responseData['file_size'],
          'cloudinary_bytes': responseData['cloudinary_bytes'],
        };
      } else {
        return {
          'success': false,
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
          'message': responseData['message'] ?? 'Upload failed'
        };
      }
    } catch (e) {
      // Handle any errors that occur during the request
      return {
        'success': false,
        'return_code': 'CLIENT_ERROR',
        'message': 'Failed to upload image: $e'
      };
    }
  }
}
