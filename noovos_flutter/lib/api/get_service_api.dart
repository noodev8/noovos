/*
API client for the get_service endpoint
Handles retrieving detailed information about a specific service by its ID
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GetServiceApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Endpoint for get service
  static final String _endpoint = '/get_service';

  // Full URL for the API
  static final String _apiUrl = _baseUrl + _endpoint;

  /*
  * Get service details by ID
  *
  * @param serviceId ID of the service to retrieve
  * @return A map containing the service details or error information
  */
  static Future<Map<String, dynamic>> getService(int serviceId) async {
    try {
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
      };

      // Send POST request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get service details',
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
