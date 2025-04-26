/*
API service for fetching categories
Communicates with the get_categories endpoint on the server
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetCategoriesApi {
  // Endpoint for get categories
  static const String _endpoint = '/get_categories';

  // Get categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      // Send POST request with empty body using the base client
      final response = await BaseApiClient.post(_endpoint, {});

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
