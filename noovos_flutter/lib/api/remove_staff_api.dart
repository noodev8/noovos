/*
API client for the remove_staff endpoint
Allows business owners to remove staff members from their business
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class RemoveStaffApi {
  // Endpoint for remove staff
  static const String _endpoint = '/remove_staff';

  // Remove staff
  static Future<Map<String, dynamic>> removeStaff(int businessId, int appuserId) async {
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
        'appuser_id': appuserId,
      };

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove staff member',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Return error
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'SERVER_ERROR',
      };
    }
  }
}
