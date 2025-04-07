import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_user_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/dashboard_screen.dart';
import 'helpers/auth_helper.dart';
import 'styles/app_styles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initial route
  String _initialRoute = '/login';

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Check if user is already logged in
  Future<void> _checkAuth() async {
    try {
      final isLoggedIn = await AuthHelper.isLoggedIn();

      if (mounted) {
        setState(() {
          _initialRoute = isLoggedIn ? '/dashboard' : '/login';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialRoute = '/login';
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
      },
    );
  }
}
