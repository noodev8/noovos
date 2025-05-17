/*
API client for the check_booking_integrity endpoint
Checks if there are any bookings allocated to a staff member which 
the staff member no longer has a rota scheduled for.
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class CheckBookingIntegrityApi {
  // Endpoint for check booking integrity
  static const String _endpoint = '/check_booking_integrity';

  // Check booking integrity
  static Future<Map<String, dynamic>> checkBookingIntegrity({
    required int businessId,
    int? staffId,
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

      // Create request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
      };

      // Add optional staff_id if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'orphaned_bookings': responseData['orphaned_bookings'] ?? [],
          'count': responseData['count'] ?? 0,
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to check booking integrity',
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