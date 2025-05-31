/*
Show the login screen allowing users to log into the application
This screen also has an option to Register is the user is not already registered
Once logged in, it goes straight to the dashboard
*/

import 'package:flutter/material.dart';
import '../api/login_user_api.dart';
import '../styles/app_styles.dart';
import '../helpers/auth_helper.dart';
import '../helpers/staff_invitation_helper.dart';
import 'hidden_developer_screen.dart';

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({Key? key}) : super(key: key);

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // Secret tap counter for developer screen
  int _logoTapCount = 0;
  final int _requiredTaps = 5;
  DateTime? _lastTapTime;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Get user-friendly error message based on error code
  String _getUserFriendlyErrorMessage(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_FIELDS':
        return 'Please enter both email and password';
      case 'EMAIL_NOT_VERIFIED':
        return 'Please verify your email address before logging in.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      default:
        return defaultMessage;
    }
  }

  // Handle login
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call login API
      final result = await LoginUserApi.loginUser(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check if login was successful
      if (result['success']) {
        // Check if user has business owner role by querying the appuser_business_role table
        // This makes an API call to get_user_businesses which checks if the user has any businesses
        // with a 'business_owner' role
        final isBusinessOwner = await AuthHelper.isBusinessOwner();

        if (mounted) {
          // Check for staff invitations
          await StaffInvitationHelper.checkForInvitations(context);

          // Check again if the widget is still mounted after the async operation
          if (mounted) {
            if (isBusinessOwner) {
              // Navigate to business owner screen
              Navigator.pushReplacementNamed(context, '/business_owner');
            } else {
              // Navigate to dashboard
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          }
        }
      } else {
        // Handle different error cases
        final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
        final defaultMessage = result['message'] ?? 'Login failed. Please try again.';

        if (mounted) {
          // For INVALID_CREDENTIALS (user not found), silently clear form and stay on login page
          if (errorCode == 'INVALID_CREDENTIALS') {
            setState(() {
              _errorMessage = null; // Don't show error message
              _emailController.clear();
              _passwordController.clear();
            });
          } else {
            // Show error message for other error types
            setState(() {
              _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
            });

            // If email is not verified, show verification options
            if (errorCode == 'EMAIL_NOT_VERIFIED') {
              _showEmailVerificationDialog(result['email'] ?? _emailController.text.trim());
            }
          }
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        setState(() {
          _errorMessage = _getUserFriendlyErrorMessage('SERVER_ERROR',
              'Unable to connect to the server. Please check your internet connection.');
        });
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to dashboard
  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  // Show email verification dialog with options
  void _showEmailVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email_outlined,
                color: AppStyles.primaryColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Your email address needs to be verified before you can log in.',
                textAlign: TextAlign.center,
                style: AppStyles.subheadingStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'Email: $email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/email-verification',
                  arguments: {'email': email});
              },
              child: const Text('Verify Email'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Handle secret logo tap for developer screen access
  void _handleLogoTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds have passed since last tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inSeconds > 2) {
      _logoTapCount = 0;
    }

    // Update last tap time
    _lastTapTime = now;

    // Increment counter
    _logoTapCount++;

    // Check if we've reached the required number of taps
    if (_logoTapCount >= _requiredTaps) {
      _logoTapCount = 0; // Reset counter

      // Navigate to developer screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HiddenDeveloperScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header section with gradient background
          _buildGradientHeader(isTablet),
          // Form section
          Expanded(
            child: _buildFormSection(isTablet),
          ),
        ],
      ),
    );
  }

  // Build the gradient header section
  Widget _buildGradientHeader(bool isTablet) {
    final headerHeight = isTablet ? 280.0 : 240.0;

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
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
        child: Stack(
          children: [
            // Dashboard/Search button in top right
            Positioned(
              top: 10,
              right: 16,
              child: TextButton.icon(
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                label: const Text('Search', style: TextStyle(color: Colors.white, fontSize: 14)),
                onPressed: _navigateToDashboard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            // Main content centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon with secret tap detection
                  GestureDetector(
                    onTap: _handleLogoTap,
                    child: _buildLogo(isTablet),
                  ),
                  const SizedBox(height: 20),
                  // Welcome title
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  Text(
                    'Booking without the faff.',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the logo/icon
  Widget _buildLogo(bool isTablet) {
    final logoSize = isTablet ? 80.0 : 64.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/noovos_app_icon.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Build the form section
  Widget _buildFormSection(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 40 : 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sign In heading
            Text(
              'Sign In',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email field
                  _buildCleanTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  _buildCleanTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Login button
                  _buildLoginButton(),
                  const SizedBox(height: 20),

                  // Forgot password link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build clean text field matching the design
  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Build the Login button
  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black54,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
