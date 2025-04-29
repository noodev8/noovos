/*
API client for the respond_to_staff_invitation endpoint
Allows users to accept or reject staff invitations
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class RespondToStaffInvitationApi {
  // Endpoint for respond to staff invitation
  static const String _endpoint = '/respond_to_staff_invitation';

  // Respond to staff invitation
  static Future<Map<String, dynamic>> respondToStaffInvitation(int invitationId, String action) async {
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

      // Validate action
      if (action != 'accept' && action != 'reject') {
        return {
          'success': false,
          'message': 'Invalid action. Must be either "accept" or "reject"',
          'return_code': 'INVALID_ACTION',
        };
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'invitation_id': invitationId,
        'action': action,
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
          'message': responseData['message'] ?? 'Failed to respond to staff invitation',
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
