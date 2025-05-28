/*
API service for business update
Communicates with the update_business endpoint on the server
Supports updating business details and managing business images
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class UpdateBusinessApi {
  // Endpoint for update business
  static const String _endpoint = '/update_business';

  // Update business
  static Future<Map<String, dynamic>> updateBusiness({
    required int businessId,
    String? name,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? postcode,
    String? country,
    String? description,
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
      final requestBody = <String, dynamic>{
        'business_id': businessId,
      };

      // Add optional fields only if they are provided
      if (name != null) requestBody['name'] = name;
      if (email != null) requestBody['email'] = email;
      if (phone != null) requestBody['phone'] = phone;
      if (website != null) requestBody['website'] = website;
      if (address != null) requestBody['address'] = address;
      if (city != null) requestBody['city'] = city;
      if (postcode != null) requestBody['postcode'] = postcode;
      if (country != null) requestBody['country'] = country;
      if (description != null) requestBody['description'] = description;
      if (imageName != null) requestBody['image_name'] = imageName;

      // Make API call
      final response = await BaseApiClient.postWithAuth(
        _endpoint,
        requestBody,
        token,
      );

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'business': responseData['business'],
          'message': responseData['message'] ?? 'Business updated successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update business',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      // Log error for debugging (in production, use proper logging framework)
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
