/*
API service for fetching categories
Communicates with the get_categories endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GetCategoriesApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Get categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      // Construct the full URL
      final url = Uri.parse('$_baseUrl/get_categories');

      // Create headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Send POST request with empty body
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if request was successful
      if (response.statusCode == 200 &&
          (responseData['return_code'] == 'SUCCESS' || responseData['return_code'] == 'NO_CATEGORIES')) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch categories',
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
