/*
API client for the update_service endpoint
Handles updating existing services for a business
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class UpdateServiceApi {
  // Endpoint for update service
  static const String _endpoint = '/update_service';

  // Update an existing service
  static Future<Map<String, dynamic>> updateService({
    required int serviceId,
    String? serviceName,
    String? description,
    int? duration,
    double? price,
    int? bufferTime,
    int? categoryId,
    bool? active,
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

      // Create request body with service ID
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
      };

      // Add optional fields if provided
      if (serviceName != null) {
        requestBody['service_name'] = serviceName;
      }
      if (description != null) {
        requestBody['description'] = description;
      }
      if (duration != null) {
        requestBody['duration'] = duration;
      }
      if (price != null) {
        requestBody['price'] = price;
      }
      if (bufferTime != null) {
        requestBody['buffer_time'] = bufferTime;
      }
      if (categoryId != null) {
        requestBody['category_id'] = categoryId;
      }
      if (active != null) {
        requestBody['active'] = active;
      }
      if (imageName != null) {
        requestBody['image_name'] = imageName;
      }

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'],
          'service': responseData['service'],
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update service',
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
