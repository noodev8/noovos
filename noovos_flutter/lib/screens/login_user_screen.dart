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
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password. Please try again.';
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
        // Show error message
        final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
        final defaultMessage = result['message'] ?? 'Login failed. Please try again.';

        if (mounted) {
          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
          });
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
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Dashboard button
          TextButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Search', style: TextStyle(color: Colors.white)),
            onPressed: _navigateToDashboard,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or app name with secret tap detection
                  GestureDetector(
                    onTap: _handleLogoTap,
                    child: const Text(
                      'Noovos',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to your account',
                    style: AppStyles.subheadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppStyles.errorColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStyles.errorColor.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppStyles.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppStyles.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: AppStyles.inputDecoration(
                      'Email',
                      hint: 'Enter your email',
                      prefixIcon: const Icon(Icons.email),
                    ),
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
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: AppStyles.inputDecoration(
                      'Password',
                      hint: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: AppStyles.primaryButtonStyle,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: AppStyles.captionStyle,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
