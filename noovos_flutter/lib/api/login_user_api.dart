/*
API service for user login
Communicates with the login_user endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../config/app_config.dart';

class LoginUserApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Login user
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {

      // Construct the full URL
      final url = Uri.parse('$_baseUrl/login_user');

      // Create request body
      final body = jsonEncode({
        'email': email,
        'password': password,
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
