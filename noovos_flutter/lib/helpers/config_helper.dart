/*
Helper class for managing configuration settings
Provides methods for updating configuration values at runtime
*/

import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ConfigHelper {
  // Keys for SharedPreferences
  static const String _apiBaseUrlKey = 'api_base_url';
  
  // Get API base URL (with override from SharedPreferences if available)
  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey) ?? AppConfig.apiBaseUrl;
  }
  
  // Save API base URL to SharedPreferences
  static Future<void> saveApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, url);
  }
  
  // Reset API base URL to default
  static Future<void> resetApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiBaseUrlKey);
  }
}
