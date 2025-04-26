/*
API service for checking app version
Communicates with the get_app_version endpoint on the server
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetAppVersionApi {
  // Endpoint for get app version
  static const String _endpoint = '/get_app_version';

  // Get minimum app version
  static Future<Map<String, dynamic>> getMinimumVersion(String platform) async {
    try {
      // Create request body
      final body = {
        'platform': platform,
      };

      // Send POST request using the base client
      final response = await BaseApiClient.post(_endpoint, body);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': responseData,
          'minimum_version': responseData['minimum_version'],
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get minimum version',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Return error
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'SERVER_ERROR',
      };
    }
  }
}
