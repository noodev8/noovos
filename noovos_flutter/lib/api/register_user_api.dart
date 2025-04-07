/*
API service for user registration
Communicates with the register_user endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../config/app_config.dart';

class RegisterUserApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Register user
  static Future<Map<String, dynamic>> registerUser(
    String firstName,
    String lastName,
    String email,
    String password,
    String? mobile,
  ) async {
    try {
      // Construct the full URL
      final url = Uri.parse('$_baseUrl/register_user');

      // Create request body
      final body = jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'mobile': mobile,
      });

      // Send POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

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
