/*
API service for email verification functionality
Communicates with the verify_email endpoint on the server
*/

import 'dart:convert';
import 'base_api_client.dart';

class VerifyEmailApi {
  // Endpoint for email verification
  static const String _endpoint = '/verify_email';

  // Verify email with token
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      // Create request body
      final requestBody = {
        'token': token,
      };

      // Make API call using base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Email verified successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify email',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in verifyEmail: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
