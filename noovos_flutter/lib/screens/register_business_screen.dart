/*
Register Business Screen
Allows users to register a new business and become a business owner
Collects business information and submits to the server
*/

import 'package:flutter/material.dart';
import '../api/register_business_api.dart';
import '../styles/app_styles.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({Key? key}) : super(key: key);

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set default country
    _countryController.text = 'United Kingdom';
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Get user-friendly error message based on error code
  String _getUserFriendlyErrorMessage(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_FIELDS':
        return 'Please fill in all required fields';
      case 'EMAIL_EXISTS':
        return 'A business with this email already exists';
      case 'UNAUTHORIZED':
        return 'Authentication required. Please login again.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      default:
        return defaultMessage;
    }
  }

  // Handle business registration
  Future<void> _handleBusinessRegistration() async {
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
      // Call business registration API
      final result = await RegisterBusinessApi.registerBusiness(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        postcode: _postcodeController.text.trim().isNotEmpty ? _postcodeController.text.trim() : null,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if registration was successful
        if (result['success']) {
          // Show success dialog
          _showSuccessDialog(result['business']);
        } else {
          // Show error message
          final errorCode = result['return_code'] ?? 'UNKNOWN_ERROR';
          final defaultMessage = result['message'] ?? 'Failed to register business. Please try again.';

          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(errorCode, defaultMessage);
          });

          // If unauthorized, redirect to login
          if (errorCode == 'UNAUTHORIZED') {
            Navigator.pushReplacementNamed(context, '/login');
          }
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

  // Show success dialog
  void _showSuccessDialog(Map<String, dynamic> business) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Business Registered!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations! Your business "${business['name']}" has been registered successfully.',
                textAlign: TextAlign.center,
                style: AppStyles.subheadingStyle,
              ),
              const SizedBox(height: 16),
              const Text(
                'You can now manage your business and add services through the business owner dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to business owner screen and signal that business status should be refreshed
                Navigator.pushReplacementNamed(context, '/business_owner');
              },
              child: const Text('Go to Business Dashboard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Return to previous screen with a result indicating business was created
                Navigator.pop(context, true);
              },
              child: const Text('Back to Profile'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Register Business'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: const Column(
                  children: [
                    Icon(
                      Icons.business,
                      size: 48,
                      color: AppStyles.primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Register Your Business',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Join our platform and start offering your services to customers.',
                      style: AppStyles.subheadingStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

              // Business information form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Business name (required)
                    TextFormField(
                      controller: _nameController,
                      decoration: AppStyles.inputDecoration(
                        'Business Name *',
                        hint: 'Enter your business name',
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Business email (required)
                    TextFormField(
                      controller: _emailController,
                      decoration: AppStyles.inputDecoration(
                        'Business Email *',
                        hint: 'Enter your business email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your business email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone (optional)
                    TextFormField(
                      controller: _phoneController,
                      decoration: AppStyles.inputDecoration(
                        'Phone Number',
                        hint: 'Enter your business phone number',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Website (optional)
                    TextFormField(
                      controller: _websiteController,
                      decoration: AppStyles.inputDecoration(
                        'Website',
                        hint: 'Enter your business website',
                        prefixIcon: const Icon(Icons.web),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),

                    // Address section
                    const Text(
                      'Business Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: AppStyles.inputDecoration(
                        'Street Address',
                        hint: 'Enter your business address',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City and Postcode row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: AppStyles.inputDecoration(
                              'City',
                              hint: 'Enter city',
                              prefixIcon: const Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _postcodeController,
                            decoration: AppStyles.inputDecoration(
                              'Postcode',
                              hint: 'Enter postcode',
                              prefixIcon: const Icon(Icons.mail),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: AppStyles.inputDecoration(
                        'Country',
                        hint: 'Enter country',
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Business Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: AppStyles.inputDecoration(
                        'Description',
                        hint: 'Describe your business and services',
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Register button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleBusinessRegistration,
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
                    : const Text('Register Business'),
              ),
              const SizedBox(height: 20),

              // Required fields note
              const Text(
                '* Required fields',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
