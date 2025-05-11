/*
API client for the set_staff_schedule endpoint
Applies a new schedule to the database for a staff member
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class SetStaffScheduleApi {
  // Endpoint for set staff schedule
  static const String _endpoint = '/set_staff_schedule';

  // Set staff schedule
  static Future<Map<String, dynamic>> setStaffSchedule({
    required int businessId,
    required int staffId,
    required List<Map<String, dynamic>> schedule,
    bool force = false,
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

      // Validate schedule
      if (schedule.isEmpty) {
        return {
          'success': false,
          'message': 'At least one schedule entry is required',
          'return_code': 'MISSING_FIELDS',
        };
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
        'staff_id': staffId,
        'schedule': schedule,
        'force': force,
      };

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to set staff schedule',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Return error for exceptions
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
}
