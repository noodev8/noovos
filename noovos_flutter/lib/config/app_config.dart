/*
Configuration file for the Noovos application
Contains global settings and configuration values
*/

class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://192.168.1.88:3000';

  // App Settings
  static const String appName = 'Noovos';
  static const String appVersion = '1.0.0';

  // Timeout Settings (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Feature Flags
  static const bool enableDebugLogs = true;

  // Development Mode
  // Set this to false before production release to hide development tools
  static const bool developmentMode = true;
}
