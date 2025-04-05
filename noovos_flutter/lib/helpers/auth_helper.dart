/*
Helper class for authentication-related functionality
Manages JWT token storage and retrieval
Provides methods for checking if user is logged in
*/

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
}
