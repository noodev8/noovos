/*
API service for user registration
Communicates with the register_user endpoint on the server
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class RegisterUserApi {
  // Endpoint for register user
  static const String _endpoint = '/register_user';

  // Register user
  static Future<Map<String, dynamic>> registerUser(
    String firstName,
    String lastName,
    String email,
    String password,
    String? mobile,
  ) async {
    try {
      // Create request body
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'mobile': mobile,
      };

      // Send POST request using the base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if registration was successful
      if (response.statusCode == 201 && responseData['return_code'] == 'SUCCESS') {
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
          'message': responseData['message'] ?? 'Registration failed',
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
