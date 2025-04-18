import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_user_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/service_details_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/availability_check_screen.dart';
import 'styles/app_styles.dart';
import 'helpers/cart_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: initialScreen,
      routes: {
        '/login': (context) => const LoginUserScreen(),
        '/register': (context) => const RegisterUserScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/cart': (context) => const CartScreen(),
        '/availability': (context) => const AvailabilityCheckScreen(),
      },
    );
  }
}
