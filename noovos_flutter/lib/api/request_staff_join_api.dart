/*
API client for the request_staff_join endpoint
Allows business owners to send staff join requests by email
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class RequestStaffJoinApi {
  // Endpoint for request staff join
  static const String _endpoint = '/request_staff_join';

  // Request staff join
  static Future<Map<String, dynamic>> requestStaffJoin(int businessId, String email) async {
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
        'email': email,
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
          'message': responseData['message'] ?? 'Failed to send staff join request',
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
