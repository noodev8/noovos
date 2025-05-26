/*
Update Business Screen
Allows business owners to update their business details
Loads current business information and provides form to update
*/

import 'package:flutter/material.dart';
import '../api/get_user_businesses_api.dart';
import '../api/update_business_api.dart';
import '../styles/app_styles.dart';

class UpdateBusinessScreen extends StatefulWidget {
  const UpdateBusinessScreen({Key? key}) : super(key: key);

  @override
  State<UpdateBusinessScreen> createState() => _UpdateBusinessScreenState();
}

class _UpdateBusinessScreenState extends State<UpdateBusinessScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading states
  bool _isLoading = true;
  bool _isUpdating = false;

  // Business data
  List<dynamic> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;
  int? _selectedBusinessId;

  // Error message
  String? _errorMessage;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
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

  // Load user businesses
  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await GetUserBusinessesApi.getUserBusinesses();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          final businesses = result['businesses'] as List;
          // Filter only business_owner roles
          final ownedBusinesses = businesses
              .where((business) => business['role']?.toString().toLowerCase() == 'business_owner')
              .toList();

          setState(() {
            _businesses = ownedBusinesses;
          });

          // If only one business, auto-select it
          if (ownedBusinesses.length == 1) {
            _selectBusiness(ownedBusinesses[0]);
          }
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load businesses';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while loading businesses';
        });
      }
    }
  }

  // Select business and populate form
  void _selectBusiness(Map<String, dynamic> business) {
    setState(() {
      _selectedBusiness = business;
      _selectedBusinessId = business['id'];
    });

    // Populate form controllers with current business data
    _nameController.text = business['name'] ?? '';
    _emailController.text = business['email'] ?? '';
    _phoneController.text = business['phone'] ?? '';
    _websiteController.text = business['website'] ?? '';
    _addressController.text = business['address'] ?? '';
    _cityController.text = business['city'] ?? '';
    _postcodeController.text = business['postcode'] ?? '';
    _countryController.text = business['country'] ?? '';
    _descriptionController.text = business['description'] ?? '';
  }

  // Handle business update
  Future<void> _handleBusinessUpdate() async {
    if (!_formKey.currentState!.validate() || _selectedBusinessId == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final result = await UpdateBusinessApi.updateBusiness(
        businessId: _selectedBusinessId!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        postcode: _postcodeController.text.trim().isEmpty ? null : _postcodeController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        if (result['success']) {
          _showSuccessDialog();
        } else {
          setState(() {
            _errorMessage = _getUserFriendlyErrorMessage(
              result['return_code'] ?? 'UNKNOWN_ERROR',
              result['message'] ?? 'Failed to update business',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // Get user-friendly error message
  String _getUserFriendlyErrorMessage(String returnCode, String defaultMessage) {
    switch (returnCode) {
      case 'MISSING_BUSINESS_ID':
        return 'Please select a business to update.';
      case 'BUSINESS_NOT_FOUND':
        return 'Business not found or you don\'t have permission to update it.';
      case 'EMAIL_EXISTS':
        return 'A business with this email already exists. Please use a different email.';
      case 'UNAUTHORIZED':
        return 'You are not authorized to update this business.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      default:
        return defaultMessage;
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Business details updated successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to profile
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Update Business'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildUpdateForm(),
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadBusinesses,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build update form
  Widget _buildUpdateForm() {
    if (_businesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Businesses Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You don\'t have any businesses to update.',
                textAlign: TextAlign.center,
                style: AppStyles.subheadingStyle,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: AppStyles.primaryButtonStyle,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business selection (if multiple businesses)
            if (_businesses.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Business',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedBusinessId,
                      decoration: const InputDecoration(
                        labelText: 'Business *',
                        border: OutlineInputBorder(),
                      ),
                      items: _businesses.map<DropdownMenuItem<int>>((business) {
                        return DropdownMenuItem<int>(
                          value: business['id'],
                          child: Text(business['name'] ?? 'Unnamed Business'),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        if (value != null) {
                          final business = _businesses.firstWhere((b) => b['id'] == value);
                          _selectBusiness(business);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a business';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Business details form
            if (_selectedBusiness != null) ...[
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  children: [
                    const Icon(
                      Icons.business_center,
                      size: 48,
                      color: AppStyles.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update ${_selectedBusiness!['name']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update your business information below.',
                      style: AppStyles.subheadingStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Basic Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Business name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Business Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Website
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.web),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Location Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Postcode
                    TextFormField(
                      controller: _postcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postcode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.mail),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Tell customers about your business...',
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ],

            // Show error message if any
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Update button
            if (_selectedBusiness != null) ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isUpdating ? null : _handleBusinessUpdate,
                style: AppStyles.primaryButtonStyle,
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update Business'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
