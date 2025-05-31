/*
API client for the create_booking endpoint
Handles creating a new booking for a customer
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class CreateBookingApi {
  // Endpoint for create booking
  static const String _endpoint = '/create_booking';

  /*
  * Create a new booking
  *
  * @param serviceId ID of the service to book
  * @param staffId ID of the staff member to perform the service
  * @param bookingDate Date of the booking (YYYY-MM-DD format)
  * @param startTime Start time of the booking (HH:MM format)
  * @param endTime End time of the booking (HH:MM format)
  * @return A map containing the booking details or error information
  */
  static Future<Map<String, dynamic>> createBooking({
    required int serviceId,
    required int staffId,
    required String bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Get auth token
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Please register or login to make a booking',
          'return_code': 'UNAUTHORIZED',
        };
      }

      // Set up request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
        'staff_id': staffId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
      };

      // Send POST request using the base client with auth token
      final response = await BaseApiClient.postWithAuth(_endpoint, requestBody, token);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (response.statusCode == 201 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': responseData['booking'],
        };
      } else {
        // Handle error
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create booking',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
        };
      }
    } catch (e) {
      // Handle exception
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'return_code': 'EXCEPTION',
      };
    }
  }
} 