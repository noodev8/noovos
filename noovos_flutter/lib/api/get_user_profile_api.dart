/*
API service for getting user profile information
Communicates with the get_user_profile endpoint on the server
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetUserProfileApi {
  // Endpoint for get user profile
  static const String _endpoint = '/get_user_profile';

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
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

      // Create request body (empty for this endpoint)
      final requestBody = <String, dynamic>{};

      // Make API call using base client with authentication
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'user': responseData['user'],
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get user profile',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in getUserProfile: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
