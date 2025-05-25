/*
API service for user login
Communicates with the login_user endpoint on the server
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class LoginUserApi {
  // Endpoint for login user
  static const String _endpoint = '/login_user';

  // Login user
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // Create request body
      final requestBody = {
        'email': email,
        'password': password,
      };

      // Send POST request using the base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if login was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        // Save token and user data
        await AuthHelper.saveToken(responseData['token']);
        await AuthHelper.saveUserData(responseData['user']);

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
          'email': responseData['email'], // Include email for EMAIL_NOT_VERIFIED case
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
