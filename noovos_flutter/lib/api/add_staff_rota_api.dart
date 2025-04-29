/*
API client for the add_staff_rota endpoint
Adds new staff rota entries for a business
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class AddStaffRotaApi {
  // Endpoint for add staff rota
  static const String _endpoint = '/add_staff_rota';

  // Add staff rota entries
  static Future<Map<String, dynamic>> addStaffRota({
    required int businessId,
    required List<Map<String, dynamic>> entries,
  }) async {
    try {
      // Get auth token
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'return_code': 'UNAUTHORIZED',
        };
      }

      // Validate entries
      if (entries.isEmpty) {
        return {
          'success': false,
          'message': 'At least one rota entry is required',
          'return_code': 'MISSING_FIELDS',
        };
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
        'entries': entries,
      };

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
          'added_count': responseData['added_count'],
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add staff rota entries',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Return error for exceptions
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
}
