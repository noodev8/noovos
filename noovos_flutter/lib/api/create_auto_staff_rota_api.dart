/*
API client for the create_auto_staff_rota endpoint
Automatically generates staff rota entries based on staff schedules
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class CreateAutoStaffRotaApi {
  // Endpoint for create auto staff rota
  static const String _endpoint = '/create_auto_staff_rota';

  // Create auto staff rota
  static Future<Map<String, dynamic>> createAutoStaffRota({
    required int businessId,
    int? staffId,
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

      // Add optional staff_id if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

      // Make API request
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
          'generated_count': responseData['generated_count'],
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to generate staff rota',
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
