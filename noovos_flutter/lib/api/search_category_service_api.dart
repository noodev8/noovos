/*
API service for fetching services by category
Communicates with the search_category_service endpoint on the server
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SearchCategoryServiceApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Get services by category
  static Future<Map<String, dynamic>> getServicesByCategory(int categoryId) async {
    try {
      // Construct the full URL
      final url = Uri.parse('$_baseUrl/search_category_service');

      // Create headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Create request body
      final body = jsonEncode({
        'category_id': categoryId,
      });

      // Send POST request
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if request was successful
      if (response.statusCode == 200 && 
          (responseData['return_code'] == 'SUCCESS' || responseData['return_code'] == 'NO_SERVICES')) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch services for this category',
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
