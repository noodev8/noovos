/*
API client for the delete_image endpoint
Handles deleting images from Cloudinary storage
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class DeleteImageApi {
  // Endpoint for delete image
  static const String _endpoint = '/delete_image';

  /*
  * Delete an image from Cloudinary storage
  *
  * @param imageName The image name/public ID to delete
  * @param folder Optional folder name (default: 'noovos')
  * @return Map containing success status and response data
  */
  static Future<Map<String, dynamic>> deleteImage(
    String imageName, {
    String folder = 'noovos',
  }) async {
    try {
      // Get auth token
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'return_code': 'UNAUTHORIZED',
        };
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'image_name': imageName,
        'folder': folder,
      };

      // Send POST request using the base client with authentication
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Image deleted successfully',
          'deleted_image': responseData['deleted_image'],
          'return_code': responseData['return_code'],
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete image',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Handle exceptions
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
}
