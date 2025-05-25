/*
API service for business registration
Communicates with the register_business endpoint on the server
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class RegisterBusinessApi {
  // Endpoint for register business
  static const String _endpoint = '/register_business';

  // Register business
  static Future<Map<String, dynamic>> registerBusiness({
    required String name,
    required String email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? postcode,
    String? country,
    String? description,
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
      final requestBody = {
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (website != null && website.isNotEmpty) 'website': website,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (postcode != null && postcode.isNotEmpty) 'postcode': postcode,
        if (country != null && country.isNotEmpty) 'country': country,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      // Make API call using base client with authentication
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'business': responseData['business'],
          'message': responseData['message'] ?? 'Business registered successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to register business',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in registerBusiness: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
