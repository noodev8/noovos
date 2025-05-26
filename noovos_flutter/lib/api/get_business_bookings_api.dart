/*
API client for the get_business_bookings endpoint
Retrieves all bookings for a specific business with optional staff filtering
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetBusinessBookingsApi {
  // Endpoint for get business bookings
  static const String _endpoint = '/get_business_bookings';

  // Get all bookings for a business
  static Future<Map<String, dynamic>> getBusinessBookings({
    required int businessId,
    int? staffId,
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
      };

      // Add staff filter if provided
      if (staffId != null) {
        requestBody['staff_id'] = staffId;
      }

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
            'bookings': responseData['bookings'] ?? [],
          };
        } else {
          return {
            'success': false,
            'return_code': responseData['return_code'],
            'message': responseData['message'] ?? 'Failed to get bookings',
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

  // Get bookings filtered by staff member
  static Future<Map<String, dynamic>> getBookingsByStaff({
    required int businessId,
    required int staffId,
  }) async {
    return await getBusinessBookings(
      businessId: businessId,
      staffId: staffId,
    );
  }
}
