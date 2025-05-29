/*
API wrapper for get_user_bookings endpoint
This API allows users to retrieve their own bookings as customers
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetUserBookingsApi {

  /*
  * Get all bookings for the logged-in user as a customer
  *
  * @param startDate Optional start date filter (YYYY-MM-DD format)
  * @param endDate Optional end date filter (YYYY-MM-DD format)
  * @return A map containing the booking details or error information
  */
  static Future<Map<String, dynamic>> getUserBookings({
    String? startDate,
    String? endDate,
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
      final Map<String, dynamic> requestBody = {};
      
      // Add optional filters if provided
      if (startDate != null && startDate.isNotEmpty) {
        requestBody['start_date'] = startDate;
      }
      
      if (endDate != null && endDate.isNotEmpty) {
        requestBody['end_date'] = endDate;
      }

      // Make the API request
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/get_user_bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse the response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check if the API returned success
        if (responseData['return_code'] == 'SUCCESS') {
          return {
            'success': true,
            'bookings': responseData['bookings'] ?? [],
            'return_code': responseData['return_code'],
          };
        } else {
          // API returned an error
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get user bookings',
            'return_code': responseData['return_code'],
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'return_code': 'SERVER_ERROR',
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'return_code': 'NETWORK_ERROR',
      };
    }
  }
}
