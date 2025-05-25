/*
Reset Password Screen
Allows users to set a new password using a reset token from email
Validates the token and updates the user's password
*/

import 'package:flutter/material.dart';
import '../api/reset_password_api.dart';
import '../styles/app_styles.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({Key? key, this.token}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Success state - when password has been reset
  bool _passwordReset = false;

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill token if provided
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Get user-friendly error message based on error code
  String _getUserFriendlyErrorMessage(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_FIELDS':
        return 'Please fill in all required fields';
      case 'INVALID_TOKEN':
        return 'Invalid or expired reset token. Please request a new password reset.';
      case 'TOKEN_EXPIRED':
        return 'Reset token has expired. Please request a new password reset.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      default:
        return defaultMessage;
    }
  }

  // Handle password reset
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
      final result = await ResetPasswordApi.resetPassword(
        _tokenController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if request was successful
        if (result['success']) {
          // Show success state
          setState(() {
            _passwordReset = true;
          });
        } else {
          // Show error message
          final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
          final defaultMessage = result['message'] ?? 'Failed to reset password. Please try again.';

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

  // Navigate to login
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
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
            child: _passwordReset ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // Build the form view for entering new password
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
            'Set New Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your reset token and new password below.',
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

          // Token field
          TextFormField(
            controller: _tokenController,
            decoration: AppStyles.inputDecoration(
              'Reset Token',
              hint: 'Enter the token from your email',
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the reset token';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // New password field
          TextFormField(
            controller: _passwordController,
            decoration: AppStyles.inputDecoration(
              'New Password',
              hint: 'Enter your new password',
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            decoration: AppStyles.inputDecoration(
              'Confirm Password',
              hint: 'Confirm your new password',
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
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
                : const Text('Reset Password'),
          ),
          const SizedBox(height: 20),

          // Back to login button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Back to Login',
              style: TextStyle(color: AppStyles.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Build the success view after password is reset
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
          'Password Reset!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been successfully reset. You can now log in with your new password.',
          style: AppStyles.subheadingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Go to login button
        ElevatedButton(
          onPressed: _navigateToLogin,
          style: AppStyles.primaryButtonStyle,
          child: const Text('Go to Login'),
        ),
      ],
    );
  }
}
