/*
API client for the get_business_staff endpoint
Retrieves all staff members for a business (including pending requests)
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetBusinessStaffApi {
  // Endpoint for get business staff
  static const String _endpoint = '/get_business_staff';

  // Get staff for a business
  static Future<Map<String, dynamic>> getBusinessStaff(int businessId) async {
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

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'staff': responseData['staff'],
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get staff members',
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
