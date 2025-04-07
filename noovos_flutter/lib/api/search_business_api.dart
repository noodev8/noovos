/*
API client for the search_business endpoint
Handles searching for businesses and services based on a search term
Returns a list of salons and services
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../helpers/auth_helper.dart';

class SearchBusinessApi {
  // Base URL for the API
  static final String _baseUrl = AppConfig.apiBaseUrl;
  
  // Endpoint for search business
  static final String _endpoint = '/search_business';
  
  // Full URL for the API
  static final String _apiUrl = _baseUrl + _endpoint;
  
  /*
  * Search for businesses and services based on a search term
  * 
  * @param searchTerm The term to search for
  * @return A map containing the search results or error information
  */
  static Future<Map<String, dynamic>> searchBusiness(String searchTerm) async {
    try {
      // Get the authentication token
      final token = await AuthHelper.getToken();
      
      // Check if token exists
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
          'return_code': 'UNAUTHORIZED',
        };
      }
      
      // Set up headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      // Set up request body
      final body = jsonEncode({
        'search_term': searchTerm,
      });
      
      // Make the API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );
      
      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check if search was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        // Return success with results
        return {
          'success': true,
          'data': responseData,
        };
      } else if (response.statusCode == 200 && responseData['return_code'] == 'NO_RESULTS') {
        // Return success but with no results
        return {
          'success': true,
          'data': responseData,
          'message': 'No results found for your search.',
        };
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        return {
          'success': false,
          'message': 'Your session has expired. Please log in again.',
          'return_code': 'UNAUTHORIZED',
        };
      } else {
        // Return error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Search failed',
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
