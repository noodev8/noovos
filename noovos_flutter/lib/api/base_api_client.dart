/*
Base API client class
Provides common functionality for all API clients
Ensures consistent handling of API URLs and requests
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config_helper.dart';
// import '../config/app_config.dart';

class BaseApiClient {
  // Get the API base URL from SharedPreferences or default
  static Future<String> getBaseUrl() async {
    return await ConfigHelper.getApiBaseUrl();
  }

  // Create a full URL for an endpoint
  static Future<Uri> createUrl(String endpoint) async {
    final baseUrl = await getBaseUrl();
    return Uri.parse('$baseUrl$endpoint');
  }

  // Send a POST request with JSON body
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = await createUrl(endpoint);

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  // Send a POST request with JSON body and authentication token
  static Future<http.Response> postWithAuth(String endpoint, Map<String, dynamic> body, String token) async {
    final url = await createUrl(endpoint);

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // Parse response and handle common error cases
  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (responseData['return_code'] == 'SUCCESS') {
          return {
            'success': true,
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'return_code': responseData['return_code'],
            'message': responseData['message'] ?? 'Unknown error',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error parsing response: $e',
      };
    }
  }
}
