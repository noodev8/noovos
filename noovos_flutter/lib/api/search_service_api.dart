/*
API client for the search_service endpoint
Handles searching for services based on search term, location, and/or category
Returns a list of services with pagination
*/

import 'dart:convert';
import 'base_api_client.dart';

class SearchServiceApi {
  // Endpoint for search service
  static const String _endpoint = '/search_service';

  /*
  * Search for services based on various criteria
  *
  * @param searchTerm Optional term to search for
  * @param location Optional location to filter by (city or postcode)
  * @param categoryId Optional category ID to filter by
  * @param page Page number for pagination (default: 1)
  * @param limit Number of results per page (default: 20)
  * @return A map containing the search results or error information
  */
  static Future<Map<String, dynamic>> searchServices({
    String? searchTerm,
    String? location,
    int? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Set up request body with search parameters
      final Map<String, dynamic> requestBody = {
        'page': page,
        'limit': limit,
      };

      // Add optional parameters if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        requestBody['search_term'] = searchTerm;
      }

      if (location != null && location.isNotEmpty) {
        requestBody['location'] = location;
      }

      if (categoryId != null) {
        requestBody['category_id'] = categoryId;
      }

      // Make the API call using the base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if search was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        // Return success with results
        return {
          'success': true,
          'data': responseData,
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
