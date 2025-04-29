/*
Helper class for authentication-related functionality
Manages JWT token storage and retrieval
Provides methods for checking if user is logged in
*/

import 'dart:convert';
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
}
