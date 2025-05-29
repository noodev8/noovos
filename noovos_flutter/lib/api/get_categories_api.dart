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
      // Enhanced error handling for network issues
      String errorMessage;
      if (e.toString().contains('errno = 113') || e.toString().contains('No route to host')) {
        errorMessage = 'Network connection error. Please check your internet connection and server availability.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Server is not responding. Please try again later.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your connection and try again.';
      } else {
        errorMessage = 'Network error: $e';
      }

      return {
        'success': false,
        'message': errorMessage,
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
