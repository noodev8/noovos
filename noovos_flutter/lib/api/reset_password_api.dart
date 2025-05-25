/*
API service for password reset functionality
Communicates with the reset_password endpoint on the server
Handles both password reset requests and password reset confirmations
*/

import 'dart:convert';
import 'base_api_client.dart';

class ResetPasswordApi {
  // Endpoint for reset password
  static const String _endpoint = '/reset_password';

  // Request password reset - sends reset email
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      // Create request body for password reset request
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
          'message': responseData['message'] ?? 'Password reset email sent successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send password reset email',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in requestPasswordReset: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }

  // Reset password with token - sets new password
  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      // Create request body for password reset confirmation
      final requestBody = {
        'token': token,
        'new_password': newPassword,
      };

      // Make API call using base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in resetPassword: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
