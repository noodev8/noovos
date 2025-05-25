/*
Forgot Password Screen
Allows users to request a password reset by entering their email address
Sends a password reset email with a token for resetting the password
*/

import 'package:flutter/material.dart';
import '../api/reset_password_api.dart';
import '../styles/app_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controller for email input
  final _emailController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Success state - when email has been sent
  bool _emailSent = false;

  // Error message
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controller
    _emailController.dispose();
    super.dispose();
  }

  // Get user-friendly error message based on error code
  String _getUserFriendlyErrorMessage(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_FIELDS':
        return 'Please enter your email address';
      case 'USER_NOT_FOUND':
        return 'No account found with this email address';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      default:
        return defaultMessage;
    }
  }

  // Handle password reset request
  Future<void> _handlePasswordReset() async {
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
      // Call password reset API
      final result = await ResetPasswordApi.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if request was successful
        if (result['success']) {
          // Show success state
          setState(() {
            _emailSent = true;
          });
        } else {
          // Show error message
          final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
          final defaultMessage = result['message'] ?? 'Failed to send password reset email. Please try again.';

          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // Navigate back to login
  void _navigateToLogin() {
    Navigator.pop(context);
  }

  // Resend email
  void _resendEmail() {
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // Build the form view for entering email
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(
            Icons.lock_reset,
            size: 64,
            color: AppStyles.primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Reset Your Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
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

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: AppStyles.inputDecoration(
              'Email',
              hint: 'Enter your email address',
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),

          // Reset password button
          ElevatedButton(
            onPressed: _isLoading ? null : _handlePasswordReset,
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
                : const Text('Send Reset Email'),
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

  // Build the success view after email is sent
  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        const Icon(
          Icons.email_outlined,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        const Text(
          'Email Sent!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text.trim()}',
          style: AppStyles.subheadingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'Please check your email and click the link to reset your password. The link will expire in 1 hour.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Resend email button
        OutlinedButton(
          onPressed: _resendEmail,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppStyles.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Send Another Email',
            style: TextStyle(color: AppStyles.primaryColor),
          ),
        ),
        const SizedBox(height: 10),

        // Back to login button
        TextButton(
          onPressed: _navigateToLogin,
          child: const Text(
            'Back to Login',
            style: TextStyle(color: AppStyles.primaryColor),
          ),
        ),
      ],
    );
  }
}
