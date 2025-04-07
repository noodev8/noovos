/*
Configuration file for the Noovos application
Contains global settings and configuration values

DEVELOPER NOTE:
To change the API URL for different environments, simply uncomment the appropriate line below
and comment out the others. This file is the single source of truth for the API URL.
*/

class AppConfig {
  // API Configuration - UNCOMMENT THE ONE YOU NEED

  // Local development with emulator (using 10.0.2.2 to reach host machine)
  // static const String apiBaseUrl = 'http://10.0.2.2:3000';

  // Local development with physical device - Home network
  //static const String apiBaseUrl = 'http://192.168.1.88:3000';

  // Local development with physical device - Work network
  static const String apiBaseUrl = 'http://192.168.1.93:3000';

  // Production server
  // static const String apiBaseUrl = 'https://api.noovos.com';

  // App Settings
  static const String appName = 'Noovos';
  static const String appVersion = '1.0.0';

  // Timeout Settings (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Feature Flags
  static const bool enableDebugLogs = true;

  // Development Mode
  // Set this to false before production release
  static const bool developmentMode = false;
}
