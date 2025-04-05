/*
API service for user login
Communicates with the login_user endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../helpers/config_helper.dart';

class LoginUserApi {
  // Get base URL from config helper
  static Future<String> getBaseUrl() async {
    return await ConfigHelper.getApiBaseUrl();
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {

      // Use explicit approach to construct the URL
      final url = Uri(
        scheme: 'http',
        host: '192.168.1.88',
        port: 3000,
        path: '/login_user',
      );

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
