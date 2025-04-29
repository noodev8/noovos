/*
API client for the get_staff_invitations endpoint
Retrieves pending staff invitations for the authenticated user
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetStaffInvitationsApi {
  // Endpoint for get staff invitations
  static const String _endpoint = '/get_staff_invitations';

  // Get staff invitations
  static Future<Map<String, dynamic>> getStaffInvitations() async {
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

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, {}, token);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'invitations': responseData['invitations'],
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get staff invitations',
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
