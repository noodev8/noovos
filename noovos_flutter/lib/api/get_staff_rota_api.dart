/*
API client for the get_staff_rota endpoint
Retrieves staff rota entries for a business
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetStaffRotaApi {
  // Endpoint for get staff rota
  static const String _endpoint = '/get_staff_rota';

  // Get staff rota
  static Future<Map<String, dynamic>> getStaffRota({
    required int businessId,
    int? staffId,
    String? startDate,
    String? endDate,
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

      // Create request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
      };

      // Add optional parameters if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

      if (startDate != null) {
        requestBody['start_date'] = startDate;
      }

      if (endDate != null) {
        requestBody['end_date'] = endDate;
      }

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'rota': responseData['rota'],
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get staff rota',
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
