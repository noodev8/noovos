/*
Helper class for authentication-related functionality
Manages JWT token storage and retrieval
Provides methods for checking if user is logged in
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/get_user_businesses_api.dart';

class AuthHelper {
  // Keys for SharedPreferences
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Save token to shared preferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get token from shared preferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Delete token from shared preferences
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Save user data to shared preferences
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Get user data from shared preferences
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);

      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently
    }

    return null;
  }

  // Delete user data from shared preferences
  static Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      await deleteToken();
      await deleteUserData();
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if user is a business owner by querying the appuser_business_role table
  // This makes an API call to get_user_businesses which checks if the user has any businesses
  // with a 'business_owner' role. The role is stored in the appuser_business_role table,
  // not in the app_user table.
  static Future<bool> isBusinessOwner() async {
    try {
      // First check if user is logged in
      final isLoggedIn = await AuthHelper.isLoggedIn();
      if (!isLoggedIn) {
        return false;
      }

      // Call the API to get user businesses
      final result = await GetUserBusinessesApi.getUserBusinesses();

      // Check if token has expired - if so, clear auth data and return false
      if (isTokenExpired(result)) {
        await logout();
        return false;
      }

      // If the API call was successful and returned businesses, the user is a business owner
      if (result['success'] && result['businesses'] != null) {
        final businesses = result['businesses'] as List;
        // Check if any of the businesses have the user with a business_owner role
        return businesses.any((business) =>
          business['role']?.toString().toLowerCase() == 'business_owner');
      }

      return false;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  /*
  * Handle token expiration by logging out user and redirecting to login
  * This method should be called whenever an API returns TOKEN_EXPIRED, UNAUTHORIZED, or INVALID_TOKEN
  *
  * @param context The build context for navigation
  * @param showMessage Whether to show a message to the user (default: true)
  */
  static Future<void> handleTokenExpiration(BuildContext context, {bool showMessage = true}) async {
    try {
      // Clear authentication data
      await logout();

      // Show message to user if requested
      if (showMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Navigate to login screen and clear navigation stack
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /*
  * Check if an API response indicates token expiration or authentication failure
  * Returns true if the response indicates the user should be logged out
  *
  * @param result The API response result map
  * @return bool True if token has expired or is invalid
  */
  static bool isTokenExpired(Map<String, dynamic> result) {
    final returnCode = result['return_code']?.toString();
    return returnCode == 'TOKEN_EXPIRED' ||
           returnCode == 'UNAUTHORIZED' ||
           returnCode == 'INVALID_TOKEN';
  }
}
