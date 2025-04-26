/*
API client for the get_service_staff endpoint
Handles retrieving staff members who can perform a specific service
Returns a list of staff members with their details
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetServiceStaffApi {
  // Endpoint for get service staff
  static const String _endpoint = '/get_service_staff';

  // Get staff for a service
  static Future<Map<String, dynamic>> getServiceStaff(int serviceId, {int? staffId}) async {
    try {
      // Create request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
      };

      // Add staff_id if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

      // Make API call using the base client
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
