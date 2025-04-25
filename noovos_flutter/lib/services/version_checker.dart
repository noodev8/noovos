/*
Version checker service
Checks if the app version meets the minimum required version from the server
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../helpers/config_helper.dart';

class VersionChecker {
  // Check if the app version meets the minimum required version
  static Future<Map<String, dynamic>> checkVersion() async {
    try {
      // Get the API base URL
      final apiBaseUrl = await ConfigHelper.getApiBaseUrl();

      // Construct the full URL (without trailing slash to match other API calls)
      final url = Uri.parse('$apiBaseUrl/get_app_version');
      debugPrint('Using API URL: $url');

      // Get the current app version
      final currentVersion = AppConfig.appVersion;

      // Determine the platform
      final String platform = _getPlatform();

      debugPrint('Checking version for platform: $platform');
      debugPrint('API URL: $url');

      // Create request body
      final body = jsonEncode({
        'platform': platform,
      });

      // Send POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('API Response status code: ${response.statusCode}');
      debugPrint('API Response body: ${response.body}');

      // Check if the response is valid
      if (response.statusCode != 200) {
        // Try to get more information about the error
        String errorDetails = '';
        try {
          if (response.body.contains('<html>')) {
            errorDetails = ' (HTML response received instead of JSON)';
          } else {
            final errorJson = jsonDecode(response.body);
            errorDetails = ': ${errorJson['message'] ?? 'Unknown error'}';
          }
        } catch (_) {
          // Ignore parsing errors
        }

        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}$errorDetails',
          'is_update_required': false,
        };
      }

      // Parse response
      final result = jsonDecode(response.body);

      // Check if the request was successful
      if (result['return_code'] == 'SUCCESS') {
        // Get the minimum required version
        final minimumVersion = result['minimum_version'].toString();

        // Log versions for debugging
        debugPrint('Current app version: $currentVersion');
        debugPrint('Minimum required version: $minimumVersion');

        // Compare versions (simple decimal comparison)
        final isUpdateRequired = _compareVersions(currentVersion, minimumVersion) < 0;

        // Log comparison result
        debugPrint('Is update required: $isUpdateRequired');

        return {
          'success': true,
          'is_update_required': isUpdateRequired,
          'minimum_version': minimumVersion,
          'current_version': currentVersion,
        };
      } else {
        // Handle error
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to check version',
          'is_update_required': false,
        };
      }
    } catch (e) {
      // Handle error
      debugPrint('Error checking version: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'is_update_required': false,
      };
    }
  }

  // Get the platform (android, ios, web)
  static String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }

  // Compare two version strings (simple decimal comparison)
  static int _compareVersions(String version1, String version2) {
    try {
      // Convert to double for comparison
      final double v1 = double.parse(version1);
      final double v2 = double.parse(version2);

      // Simple comparison
      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
      return 0;
    } catch (e) {
      // If parsing fails, fall back to string comparison
      debugPrint('Error parsing versions: $e');
      return version1.compareTo(version2);
    }
  }
}
