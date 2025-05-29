/*
API client for the get_staff_bookings endpoint
Retrieves bookings assigned to the logged-in staff member
This allows staff to see their own bookings and indicates their business connection
*/

import 'dart:convert';
import '../helpers/auth_helper.dart';
import 'base_api_client.dart';

class GetStaffBookingsApi {
  // Endpoint for get staff bookings
  static const String _endpoint = '/get_staff_bookings';

  // Get bookings for the logged-in staff member
  // This is the main method that staff will use to see their bookings
  static Future<Map<String, dynamic>> getStaffBookings({
    int? businessId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Get auth token from storage
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'return_code': 'UNAUTHORIZED',
        };
      }

      // Create request body with optional parameters
      final Map<String, dynamic> requestBody = {};

      // Add business filter if provided (useful if staff works for multiple businesses)
      if (businessId != null) {
        requestBody['business_id'] = businessId;
      }

      // Add date range filters if provided
      if (startDate != null) {
        requestBody['start_date'] = startDate;
      }

      if (endDate != null) {
        requestBody['end_date'] = endDate;
      }

      // Make API call with authentication
      final response = await BaseApiClient.postWithAuth(
        _endpoint,
        requestBody,
        token,
      );

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if request was successful
      if (response.statusCode == 200 && responseData['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'bookings': responseData['bookings'] ?? [],
        };
      } else {
        // Return error from server
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to retrieve staff bookings',
          'return_code': responseData['return_code'] ?? 'UNKNOWN_ERROR',
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

  // Get staff bookings for a specific business
  // Useful when staff works for multiple businesses
  static Future<Map<String, dynamic>> getStaffBookingsForBusiness({
    required int businessId,
    String? startDate,
    String? endDate,
  }) async {
    return await getStaffBookings(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get staff bookings for today only
  // This is useful for showing today's schedule
  static Future<Map<String, dynamic>> getTodayStaffBookings({
    int? businessId,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return await getStaffBookings(
      businessId: businessId,
      startDate: todayString,
      endDate: todayString,
    );
  }

  // Get staff bookings for this week
  // Useful for showing weekly schedule
  static Future<Map<String, dynamic>> getThisWeekStaffBookings({
    int? businessId,
  }) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final startDateString = '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
    final endDateString = '${endOfWeek.year}-${endOfWeek.month.toString().padLeft(2, '0')}-${endOfWeek.day.toString().padLeft(2, '0')}';
    
    return await getStaffBookings(
      businessId: businessId,
      startDate: startDateString,
      endDate: endDateString,
    );
  }

  // Get upcoming staff bookings (from today onwards)
  // This is useful for showing future appointments
  static Future<Map<String, dynamic>> getUpcomingStaffBookings({
    int? businessId,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return await getStaffBookings(
      businessId: businessId,
      startDate: todayString,
      // No end date means all future bookings
    );
  }

  // Get staff bookings for a specific date range
  // This is useful for custom date filtering
  static Future<Map<String, dynamic>> getStaffBookingsForDateRange({
    required String startDate,
    required String endDate,
    int? businessId,
  }) async {
    return await getStaffBookings(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
