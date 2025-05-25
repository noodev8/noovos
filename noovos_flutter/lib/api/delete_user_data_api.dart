/*
API service for deleting user data
Communicates with the delete_user_data endpoint on the server
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class DeleteUserDataApi {
  // Endpoint for delete user data
  static const String _endpoint = '/delete_user_data';

  // Delete user data
  static Future<Map<String, dynamic>> deleteUserData(String confirmation) async {
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
        'confirmation': confirmation,
      };

      // Make API call using base client with authentication
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final responseData = json.decode(response.body);

      // Check if request was successful based on return code
      if (responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': responseData['message'] ?? 'User data deleted successfully',
          'return_code': responseData['return_code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete user data',
          'return_code': responseData['return_code'],
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error in deleteUserData: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
