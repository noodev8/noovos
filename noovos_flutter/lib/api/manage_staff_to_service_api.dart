/*
API client for managing staff assignments to services
Handles adding and removing staff members from services
*/

import 'dart:convert';
import 'base_api_client.dart';
import '../helpers/auth_helper.dart';

class ManageStaffToServiceApi {
  // Endpoint for manage staff to service
  static const String _endpoint = '/manage_staff_to_service';

  // Add staff to a service
  static Future<Map<String, dynamic>> addStaffToService({
    required String serviceId,
    required String staffId,
    required String businessId,
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

      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
        'staff_id': staffId,
        'business_id': businessId,
        'action': 'add'
      };

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add staff to service',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }

  // Remove staff from a service
  static Future<Map<String, dynamic>> removeStaffFromService({
    required String serviceId,
    required String staffId,
    required String businessId,
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

      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
        'staff_id': staffId,
        'business_id': businessId,
        'action': 'remove'
      };

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove staff from service',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
} 