/*
Helper class for managing configuration settings
Provides methods for updating configuration values at runtime
*/

import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ConfigHelper {
  // Keys for SharedPreferences
  static const String _apiBaseUrlKey = 'api_base_url';
  static const String _useCustomUrlKey = 'use_custom_url';

  // Flag to track if this is the first API call since app start
  static bool _isFirstApiCall = true;

  // Get API base URL
  // - On app startup (first call): Always use the hard-coded value from AppConfig
  // - Subsequent calls: Use the value from SharedPreferences if available
  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // If this is the first API call since app start, use the hard-coded value
    if (_isFirstApiCall) {
      _isFirstApiCall = false;

      // Clear any custom URL flag
      await prefs.setBool(_useCustomUrlKey, false);

      return AppConfig.apiBaseUrl;
    }

    // For subsequent calls, check if we should use a custom URL
    final useCustomUrl = prefs.getBool(_useCustomUrlKey) ?? false;

    if (useCustomUrl) {
      // Use the custom URL from SharedPreferences if available
      return prefs.getString(_apiBaseUrlKey) ?? AppConfig.apiBaseUrl;
    } else {
      // Otherwise, use the hard-coded value
      return AppConfig.apiBaseUrl;
    }
  }

  // Save API base URL to SharedPreferences
  static Future<void> saveApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, url);
    await prefs.setBool(_useCustomUrlKey, true);
  }

  // Reset API base URL to default
  static Future<void> resetApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiBaseUrlKey);
    await prefs.setBool(_useCustomUrlKey, false);
  }
}
