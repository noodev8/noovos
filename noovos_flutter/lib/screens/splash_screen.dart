/*
Splash Screen for Noovos Application
Displays the Noovos logo with tagline "Booking without the faff" on gradient background
Shows for 5 seconds then navigates to dashboard
Responsive design that scales well on mobile and tablet
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar to transparent for full-screen splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Start animations
    _animationController.forward();

    // Navigate to dashboard after splash duration
    _navigateToDashboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Navigate to dashboard after 3 seconds
  Future<void> _navigateToDashboard() async {
    await Future.delayed(const Duration(seconds: 5));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Gradient background matching the design (blue to pink)
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4F46E5), // Blue
              Color(0xFF7C3AED), // Purple
              Color(0xFFEC4899), // Pink
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(isTablet),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Build the Noovos logo with tagline
  Widget _buildLogo(bool isTablet) {
    // Calculate responsive logo size
    final logoSize = isTablet ? 180.0 : 140.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main logo text
        _buildNoovosText(logoSize),
        // Spacing between logo and tagline
        const SizedBox(height: 20),
        // Tagline text
        _buildTagline(isTablet),
      ],
    );
  }

  // Build the Noovos text logo with custom styling
  Widget _buildNoovosText(double logoSize) {
    return Text(
      'noovos',
      style: TextStyle(
        fontSize: logoSize * 0.5,
        fontWeight: FontWeight.w200,
        color: Colors.white,
        letterSpacing: 8.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  // Build the tagline text with complementary styling
  Widget _buildTagline(bool isTablet) {
    // Calculate responsive tagline size (smaller than logo)
    final taglineSize = isTablet ? 18.0 : 16.0;

    return Text(
      'Booking without the faff',
      style: TextStyle(
        fontSize: taglineSize,
        fontWeight: FontWeight.w300,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
