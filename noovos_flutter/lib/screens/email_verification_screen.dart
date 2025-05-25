/*
Email Verification Screen
Allows users to verify their email address using a verification token
Also provides option to resend verification email
*/

import 'package:flutter/material.dart';
import '../api/verify_email_api.dart';
import '../api/resend_verification_api.dart';
import '../styles/app_styles.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? token;
  final String? email;

  const EmailVerificationScreen({Key? key, this.token, this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();

  // Loading states
  bool _isVerifying = false;
  bool _isResending = false;

  // Success state - when email has been verified
  bool _emailVerified = false;

  // Error message
  String? _errorMessage;

  // Success message for resend
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill token and email if provided
    if (widget.token != null) {
      _tokenController.text = widget.token!;
      // Auto-verify if token is provided
      _handleEmailVerification();
    }
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from other screens
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['email'] != null && _emailController.text.isEmpty) {
        _emailController.text = args['email'];
      }
      if (args['token'] != null && _tokenController.text.isEmpty) {
        _tokenController.text = args['token'];
        // Auto-verify if token is provided
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleEmailVerification();
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Get user-friendly error message based on error code
  String _getUserFriendlyErrorMessage(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_FIELDS':
        return 'Please enter the verification token';
      case 'INVALID_TOKEN':
        return 'Invalid verification token. Please check your email or request a new one.';
      case 'TOKEN_EXPIRED':
        return 'Verification token has expired. Please request a new verification email.';
      case 'ALREADY_VERIFIED':
        return 'Email address is already verified.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      default:
        return defaultMessage;
    }
  }

  // Handle email verification
  Future<void> _handleEmailVerification() async {
    // Validate form if token is not pre-filled
    if (widget.token == null && !_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Call email verification API
      final result = await VerifyEmailApi.verifyEmail(
        _tokenController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        // Check if request was successful
        if (result['success']) {
          // Show success state
          setState(() {
            _emailVerified = true;
          });
        } else {
          // Show error message
          final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
          final defaultMessage = result['message'] ?? 'Failed to verify email. Please try again.';

          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // Handle resend verification email
  Future<void> _handleResendVerification() async {
    // Check if email is provided
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address to resend verification';
      });
      return;
    }

    // Set loading state
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Call resend verification API
      final result = await ResendVerificationApi.resendVerification(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        // Check if request was successful
        if (result['success']) {
          // Show success message
          setState(() {
            _successMessage = result['message'] ?? 'Verification email sent successfully';
          });
        } else {
          // Show error message
          final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
          final defaultMessage = result['message'] ?? 'Failed to send verification email. Please try again.';

          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // Navigate to login
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Navigate to dashboard
  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: _emailVerified ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // Build the form view for entering verification token
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(
            Icons.email_outlined,
            size: 64,
            color: AppStyles.primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter the verification token from your email to verify your account.',
            style: AppStyles.subheadingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Success message
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _successMessage!,
                style: TextStyle(color: Colors.green.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Token field
          TextFormField(
            controller: _tokenController,
            decoration: AppStyles.inputDecoration(
              'Verification Token',
              hint: 'Enter the token from your email',
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the verification token';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Email field for resending
          TextFormField(
            controller: _emailController,
            decoration: AppStyles.inputDecoration(
              'Email (for resending)',
              hint: 'Enter your email address',
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 30),

          // Verify email button
          ElevatedButton(
            onPressed: _isVerifying ? null : _handleEmailVerification,
            style: AppStyles.primaryButtonStyle,
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify Email'),
          ),
          const SizedBox(height: 15),

          // Resend verification button
          OutlinedButton(
            onPressed: _isResending ? null : _handleResendVerification,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppStyles.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isResending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppStyles.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Resend Verification Email',
                    style: TextStyle(color: AppStyles.primaryColor),
                  ),
          ),
          const SizedBox(height: 20),

          // Back to login button
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Back to Login',
              style: TextStyle(color: AppStyles.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Build the success view after email is verified
  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        const Text(
          'Email Verified!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your email address has been successfully verified. Your account is now fully activated.',
          style: AppStyles.subheadingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Continue to dashboard button
        ElevatedButton(
          onPressed: _navigateToDashboard,
          style: AppStyles.primaryButtonStyle,
          child: const Text('Continue to App'),
        ),
        const SizedBox(height: 10),

        // Go to login button
        TextButton(
          onPressed: _navigateToLogin,
          child: const Text(
            'Go to Login',
            style: TextStyle(color: AppStyles.primaryColor),
          ),
        ),
      ],
    );
  }
}
