/*
API client for the search_business endpoint
Handles searching for businesses and services based on a search term
Returns a list of salons and services
Note: This API does not require authentication
*/

import 'dart:convert';
import 'base_api_client.dart';

class SearchBusinessApi {
  // Endpoint for search business
  static const String _endpoint = '/search_business';

  /*
  * Search for businesses and services based on a search term
  *
  * @param searchTerm The term to search for
  * @return A map containing the search results or error information
  */
  static Future<Map<String, dynamic>> searchBusiness(String searchTerm) async {
    try {
      // Set up request body
      final body = {
        'search_term': searchTerm,
      };

      // Make the API call using the base client
      final response = await BaseApiClient.post(_endpoint, body);

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
