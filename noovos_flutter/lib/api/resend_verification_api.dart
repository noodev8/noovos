/*
API service for resending email verification
Communicates with the resend_verification endpoint on the server
*/

import 'dart:convert';
import 'base_api_client.dart';

class ResendVerificationApi {
  // Endpoint for resending verification email
  static const String _endpoint = '/resend_verification';

  // Resend verification email
  static Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      // Create request body
      final requestBody = {
        'email': email,
      };

      // Make API call using base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Verification email sent successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send verification email',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in resendVerification: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
