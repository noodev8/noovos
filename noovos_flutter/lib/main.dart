import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_user_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/business_owner_screen.dart';
//import 'screens/business_staff_management_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/availability_check_screen.dart';
import 'styles/app_styles.dart';
import 'helpers/cart_helper.dart';
import 'helpers/config_helper.dart';
import 'api/get_app_version_api.dart';
import 'widgets/version_mismatch_popup.dart';
import 'config/app_config.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Reset API URL to default from config file on startup
  await ConfigHelper.resetApiBaseUrl();

  // Initialize cart helper
  await CartHelper.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initial route - always start with dashboard
  String _initialRoute = '/dashboard';

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupMockData();
  }

  // Setup for dashboard
  Future<void> _setupMockData() async {
    try {
      // Just set the initial route to dashboard without creating mock user data
      // since we've redesigned the dashboard to work without user data
      if (mounted) {
        setState(() {
          _initialRoute = '/dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'Noovos',
        theme: ThemeData(
          primaryColor: AppStyles.primaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primaryColor),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Determine which screen to show based on login status
    Widget initialScreen;
    if (_initialRoute == '/dashboard') {
      initialScreen = const DashboardScreen();
    } else if (_initialRoute == '/register') {
      initialScreen = const RegisterUserScreen();
    } else {
      initialScreen = const LoginUserScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noovos',
      theme: ThemeData(
        primaryColor: AppStyles.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primaryColor),
        useMaterial3: true,
      ),
      home: VersionPopupWrapper(child: initialScreen),
      routes: {
        '/login': (context) => const LoginUserScreen(),
        '/register': (context) => const RegisterUserScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/business_owner': (context) => const BusinessOwnerScreen(),
        '/cart': (context) => const CartScreen(),
        '/availability': (context) => const AvailabilityCheckScreen(),
      },
    );
  }
}

// Wrapper widget to check app version
class VersionPopupWrapper extends StatefulWidget {
  final Widget child;

  const VersionPopupWrapper({super.key, required this.child});

  @override
  State<VersionPopupWrapper> createState() => _VersionPopupWrapperState();
}

class _VersionPopupWrapperState extends State<VersionPopupWrapper> {
  // Version check state
  bool _isChecking = true;
  bool _isUpdateRequired = false;
  String _minimumVersion = '';
  String _currentVersion = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Check version after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  // Check if the app version meets the minimum required version
  Future<void> _checkVersion() async {
    try {
      // Get platform
      String platform = 'android';
      if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        platform = 'web'; // Use 'web' for desktop platforms
      }

      // Get current app version
      final currentVersion = AppConfig.appVersion;

      // Check version using the direct API approach
      final result = await GetAppVersionApi.getMinimumVersion(platform);

      if (mounted) {
        setState(() {
          _isChecking = false;

          if (result['success']) {
            final minimumVersion = result['minimum_version'].toString();

            // Compare versions (simple decimal comparison)
            final isUpdateRequired = _compareVersions(currentVersion, minimumVersion) < 0;

            _isUpdateRequired = isUpdateRequired;
            _minimumVersion = minimumVersion;
            _currentVersion = currentVersion;

            // Show version mismatch popup if update is required
            if (_isUpdateRequired) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                VersionMismatchPopup.show(context, _currentVersion, _minimumVersion);
              });
            }
          } else {
            // Handle error - we'll allow the app to continue if version check fails
            _errorMessage = result['message'];
            _isUpdateRequired = false;
          }
        });
      }
    } catch (e) {
      // Handle error - we'll allow the app to continue if version check fails
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Failed to check version: $e';
          _isUpdateRequired = false;
        });
      }
    }
  }

  // Compare two version strings (simple decimal comparison)
  int _compareVersions(String version1, String version2) {
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
      return version1.compareTo(version2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking version
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Checking app version...'),
            ],
          ),
        ),
      );
    }

    // Show error message if there was an error checking version
    if (_errorMessage.isNotEmpty) {
      // Log the error but continue with the app
      // In a production app, you would use a proper logging framework
      debugPrint('Version check error: $_errorMessage');
    }

    // Show the child widget if no update is required
    return widget.child;
  }
}
