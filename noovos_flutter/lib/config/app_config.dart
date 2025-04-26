/*
Configuration file for the Noovos application
Contains global settings and configuration values

DEVELOPER NOTE:
To change the API URL for different environments, simply uncomment the appropriate line below
and comment out the others. This file is the single source of truth for the API URL.
*/

class AppConfig {
  static const String apiBaseUrl = 'http://192.168.1.88:3000'; // Home
  // static const String apiBaseUrl = 'http://192.168.1.88:3000'; // Grays Aunty
  // static const String apiBaseUrl = 'http://192.168.1.230:3000'; // Grays Costas
  // static const String apiBaseUrl = 'http://192.168.1.94:3000'; // 3 Cumberland
  // static const String apiBaseUrl = 'http://192.168.1.174:3000'; // Chippy

  // VPS Server
  // static const String apiBaseUrl = 'https://api.noovos.com';
  // static const String apiBaseUrl = 'https://api.noovos.com';
  // static const String apiBaseUrl = 'http://77.68.13.150:3001'; // Server Test

  // App Settings
  static const String appName = 'Noovos';
  static const String appVersion = '1.01';

  // Image Server URL
  static const String imageBaseUrl = 'https://noovos.brookfieldcomfort.com/image';

  // Timeout Settings (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Feature Flags
  static const bool enableDebugLogs = true;

}
