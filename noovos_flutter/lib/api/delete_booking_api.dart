/*
API client for the delete_booking endpoint
Deletes a booking for business owners
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class DeleteBookingApi {
  // Endpoint for delete booking
  static const String _endpoint = '/delete_booking';

  // Delete a booking
  static Future<Map<String, dynamic>> deleteBooking({
    required int bookingId,
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
        'booking_id': bookingId,
      };

      // Make API call
      final response = await BaseApiClient.postWithAuth(
        _endpoint,
        requestBody,
        token,
      );

      // Parse response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['return_code'] == 'SUCCESS') {
          return {
            'success': true,
            'return_code': responseData['return_code'],
            'message': responseData['message'] ?? 'Booking deleted successfully',
            'deleted_booking': responseData['deleted_booking'],
          };
        } else {
          return {
            'success': false,
            'return_code': responseData['return_code'],
            'message': responseData['message'] ?? 'Failed to delete booking',
          };
        }
      } else {
        // Handle HTTP error
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'return_code': errorData['return_code'] ?? 'HTTP_ERROR',
          'message': errorData['message'] ?? 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      return {
        'success': false,
        'return_code': 'NETWORK_ERROR',
        'message': 'Network error: $e',
      };
    }
  }
}
