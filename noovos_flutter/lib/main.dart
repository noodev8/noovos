import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/login_user_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/register_business_screen.dart';
import 'screens/update_business_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/business_owner_screen.dart';
//import 'screens/business_staff_management_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/availability_check_screen.dart';
import 'screens/comprehensive_bookings_screen.dart';
import 'styles/app_styles.dart';
import 'helpers/cart_helper.dart';
import 'helpers/config_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noovos',
      theme: ThemeData(
        primaryColor: AppStyles.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primaryColor),
        useMaterial3: true,
      ),
      // Always start with splash screen
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginUserScreen(),
        '/register': (context) => const RegisterUserScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/register-business': (context) => const RegisterBusinessScreen(),
        '/update_business': (context) => const UpdateBusinessScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/business_owner': (context) => const BusinessOwnerScreen(),
        '/cart': (context) => const CartScreen(),
        '/availability': (context) => const AvailabilityCheckScreen(),
        '/bookings': (context) => const ComprehensiveBookingsScreen(),
      },
    );
  }
}

// Simple wrapper widget (previously used for version checking)
class VersionPopupWrapper extends StatelessWidget {
  final Widget child;

  const VersionPopupWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Simply return the child widget without any version checking
    return child;
  }
}
