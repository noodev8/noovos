/*
API client for the get_service endpoint
Handles retrieving detailed information about a specific service by its ID
Also provides methods to get all services for a business
*/

import 'dart:convert';
import 'base_api_client.dart';

class GetServiceApi {
  // Endpoint for get service
  static const String _endpoint = '/get_service';

  // Endpoint for get business services
  static const String _businessServicesEndpoint = '/get_business_services';

  /*
  * Get service details by ID
  *
  * @param serviceId ID of the service to retrieve
  * @return A map containing the service details or error information
  */
  static Future<Map<String, dynamic>> getService(int serviceId) async {
    try {
      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
      };

      // Send POST request using the base client
      final response = await BaseApiClient.post(_endpoint, requestBody);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get service details',
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

  /*
  * Get all services for a business
  *
  * @param businessId ID of the business to get services for
  * @return A map containing the list of services or error information
  */
  static Future<Map<String, dynamic>> getBusinessServices(int businessId) async {
    try {
      // Set up request body
      final Map<String, dynamic> requestBody = {
        'business_id': businessId,
      };

      // Send POST request using the base client
      final response = await BaseApiClient.post(_businessServicesEndpoint, requestBody);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'services': responseData['services'] ?? [],
        };
      } else {
        // Handle error response
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get business services',
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
