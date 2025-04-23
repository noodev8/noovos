/*
API client for the get_service_slot_x1 endpoint
Handles retrieving available time slots for a specific service on a given date
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GetServiceSlotX1Api {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Endpoint for get service slot x1
  static final String _endpoint = '/get_service_slot_x1';

  // Full URL for the API
  static final String _apiUrl = _baseUrl + _endpoint;

  /*
  * Get available slots for a service on a specific date
  *
  * @param serviceId ID of the service to check availability for
  * @param date Date to check availability for (YYYY-MM-DD format)
  * @param staffId Optional ID of a specific staff member
  * @param timePreference Optional time preference ('morning', 'afternoon', or 'any')
  * @return A map containing the available slots or error information
  */
  static Future<Map<String, dynamic>> getServiceSlots({
    required int serviceId,
    required String date,
    int? staffId,
    String timePreference = 'any',
  }) async {
    try {
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
        'date': date,
        'time_preference': timePreference.toLowerCase(),
      };

      // Add staff_id if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

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
        // Handle error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get available slots',
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
