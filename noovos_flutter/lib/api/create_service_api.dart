/*
API client for the create_service endpoint
Handles creating new services for a business
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class CreateServiceApi {
  // Endpoint for create service
  static const String _endpoint = '/create_service';

  // Create a new service
  static Future<Map<String, dynamic>> createService({
    required int businessId,
    required String serviceName,
    String? description,
    required int duration,
    required double price,
    int? bufferTime,
    int? categoryId,
    String? imageName,
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
        'service_name': serviceName,
        'duration': duration,
        'price': price,
      };

      // Add optional fields if provided
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }
      if (bufferTime != null) {
        requestBody['buffer_time'] = bufferTime;
      }
      if (categoryId != null) {
        requestBody['category_id'] = categoryId;
      }
      if (imageName != null && imageName.isNotEmpty) {
        requestBody['image_name'] = imageName;
      }

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 201 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
          'service': responseData['service'],
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create service',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Handle exceptions
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
}
