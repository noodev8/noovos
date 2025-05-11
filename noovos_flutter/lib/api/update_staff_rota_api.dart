/*
API client for the update_staff_rota endpoint
Updates an existing staff rota entry
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class UpdateStaffRotaApi {
  // Endpoint for update staff rota
  static const String _endpoint = '/update_staff_rota';

  // Update staff rota entry
  static Future<Map<String, dynamic>> updateStaffRota({
    required int businessId,
    required int rotaId,
    int? staffId,
    String? rotaDate,
    String? startTime,
    String? endTime,
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

      // Check if at least one field to update is provided
      if (staffId == null && rotaDate == null && startTime == null && endTime == null) {
        return {
          'success': false,
          'message': 'At least one field to update is required',
          'return_code': 'MISSING_FIELDS',
        };
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
        'rota_id': rotaId,
      };

      // Add optional parameters if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

      if (rotaDate != null) {
        requestBody['rota_date'] = rotaDate;
      }

      if (startTime != null) {
        requestBody['start_time'] = startTime;
      }

      if (endTime != null) {
        requestBody['end_time'] = endTime;
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
        };
      } else {
        // Return error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update staff rota entry',
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
