/*
API client for the get_service_slot_x3 endpoint
Handles retrieving available sequential time slots for three different services
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetServiceSlotX3Api {
  // Endpoint for get service slot x3
  static const String _endpoint = '/get_service_slot_x3';

  /*
  * Get available sequential slots for three services on a specific date
  *
  * @param serviceId1 ID of the first service
  * @param serviceId2 ID of the second service
  * @param serviceId3 ID of the third service
  * @param date Date to check availability for (YYYY-MM-DD format)
  * @param staffId1 Optional ID of the staff member for first service
  * @param staffId2 Optional ID of the staff member for second service
  * @param staffId3 Optional ID of the staff member for third service
  * @param timePreference Optional time preference ('morning', 'afternoon', or 'any')
  * @return A map containing the available sequential slots or error information
  */
  static Future<Map<String, dynamic>> getServiceSlots({
    required int serviceId1,
    required int serviceId2,
    required int serviceId3,
    required String date,
    int? staffId1,
    int? staffId2,
    int? staffId3,
    String timePreference = 'any',
  }) async {
    try {
      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id_1': serviceId1,
        'service_id_2': serviceId2,
        'service_id_3': serviceId3,
        'date': date,
        'time_preference': timePreference.toLowerCase(),
      };

      // Add staff IDs if provided
      if (staffId1 != null) {
        requestBody['staff_id_1'] = staffId1;
      }
      if (staffId2 != null) {
        requestBody['staff_id_2'] = staffId2;
      }
      if (staffId3 != null) {
        requestBody['staff_id_3'] = staffId3;
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