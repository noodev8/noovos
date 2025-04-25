/*
API service for checking app version
Communicates with the get_app_version endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GetAppVersionApi {
  // Base URL for the API - use the same direct approach as other working APIs
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Get minimum app version
  static Future<Map<String, dynamic>> getMinimumVersion(String platform) async {
    try {
      // Construct the full URL - exactly like other working APIs
      final url = Uri.parse('$_baseUrl/get_app_version');

      // Create headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Create request body
      final body = jsonEncode({
        'platform': platform,
      });

      // Send POST request
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Check if the response is valid
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if request was successful
      if (responseData['return_code'] == 'SUCCESS') {
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
