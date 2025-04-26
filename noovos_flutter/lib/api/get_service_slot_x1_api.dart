/*
API client for the get_service_slot_x1 endpoint
Handles retrieving available time slots for a specific service on a given date
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetServiceSlotX1Api {
  // Endpoint for get service slot x1
  static const String _endpoint = '/get_service_slot_x1';

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

      // Send POST request using the base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

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
