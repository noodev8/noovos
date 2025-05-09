/*
API client for the check_schedule_conflict endpoint
Checks if a new schedule has conflicts with existing bookings
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class CheckScheduleConflictApi {
  // Endpoint for check schedule conflict
  static const String _endpoint = '/check_schedule_conflict';

  // Check schedule conflict
  static Future<Map<String, dynamic>> checkScheduleConflict({
    required int businessId,
    required int staffId,
    required List<Map<String, dynamic>> schedule,
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
      };

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'has_conflicts': responseData['has_conflicts'] ?? false,
          'conflicts': responseData['conflicts'] ?? [],
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to check schedule conflicts',
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
