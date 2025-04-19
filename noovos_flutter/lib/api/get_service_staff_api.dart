/*
API client for the get_service_staff endpoint
Handles retrieving staff members who can perform a specific service
Returns a list of staff members with their details
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GetServiceStaffApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Endpoint for get service staff
  static final String _endpoint = '/get_service_staff';

  // Full URL for the API
  static final String _apiUrl = _baseUrl + _endpoint;

  // Get staff for a service
  static Future<Map<String, dynamic>> getServiceStaff(int serviceId) async {
    try {
      // Create request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
      };

      // Make API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
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
        // Handle error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get staff members',
        };
      }
    } catch (e) {
      // Handle exception
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
}
