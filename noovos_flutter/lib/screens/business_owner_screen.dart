/*
Business Owner Landing Page
This screen shows businesses owned by the user
Allows navigation back to the normal user search/dashboard
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/auth_helper.dart';
import '../helpers/image_helper.dart';
import '../api/get_user_businesses_api.dart';

class BusinessOwnerScreen extends StatefulWidget {
  const BusinessOwnerScreen({Key? key}) : super(key: key);

  @override
  State<BusinessOwnerScreen> createState() => _BusinessOwnerScreenState();
}

class _BusinessOwnerScreenState extends State<BusinessOwnerScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Businesses
  List<dynamic> _businesses = [];

  @override
  void initState() {
    super.initState();

    // Load businesses
    _loadBusinesses();
  }

  // Debug information
  Map<String, dynamic>? _debugInfo;

  // Load businesses
  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugInfo = null;
    });

    try {
      // Get user data for debugging
      final userData = await AuthHelper.getUserData();
      final userId = userData?['id'];

      // Call API to get businesses
      final result = await GetUserBusinessesApi.getUserBusinesses();

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _businesses = result['businesses'];

            // If no businesses found, set a more descriptive error message
            if (_businesses.isEmpty) {
              _errorMessage = 'No businesses found for user ID: $userId. This could mean you don\'t have any business owner roles assigned in the database.';
            }
          } else {
            _errorMessage = '${result['message']} (User ID: $userId)';

            // Store debug information if available
            if (result['debug'] != null) {
              _debugInfo = result['debug'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    await AuthHelper.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  // Switch to customer mode
  void _switchToCustomerMode() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Switch to customer mode button
          TextButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Search', style: TextStyle(color: Colors.white)),
            onPressed: _switchToCustomerMode,
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _businesses.isEmpty
                  ? _buildEmptyView()
                  : _buildBusinessList(),
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
              size: 48,
              color: AppStyles.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading businesses',
              style: AppStyles.subheadingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppStyles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Debug information
            FutureBuilder<Map<String, dynamic>?>(
              future: AuthHelper.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final userData = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${userData['id']}'),
                        Text('Name: ${userData['name']}'),
                        Text('Email: ${userData['email']}'),
                        Text('Account Level: ${userData['account_level']}'),

                        // Show API debug info if available
                        if (_debugInfo != null) ...[
                          const SizedBox(height: 16),
                          const Text('API Debug Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          // User details from API
                          if (_debugInfo!['user_details'] != null) ...[
                            Text('User ID from API: ${_debugInfo!['user_details']['id']}'),
                            Text('User Email from API: ${_debugInfo!['user_details']['email']}'),
                            Text('User Role from API: ${_debugInfo!['user_details']['role']}'),
                          ],

                          // Roles from API
                          if (_debugInfo!['roles'] != null) ...[
                            const SizedBox(height: 8),
                            const Text('User Roles:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),

                            if ((_debugInfo!['roles'] as List).isEmpty)
                              const Text('No roles found for this user'),

                            for (var role in _debugInfo!['roles'])
                              Text('Business ID: ${role['business_id']}, Role: ${role['role']}'),
                          ],
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loadBusinesses,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _switchToCustomerMode,
              child: const Text('Go to Search'),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty view
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Businesses Found',
              style: AppStyles.subheadingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any businesses associated with your account.',
              style: AppStyles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Debug information
            FutureBuilder<Map<String, dynamic>?>(
              future: AuthHelper.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final userData = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${userData['id']}'),
                        Text('Name: ${userData['name']}'),
                        Text('Email: ${userData['email']}'),
                        Text('Account Level: ${userData['account_level']}'),

                        // Show API debug info if available
                        if (_debugInfo != null) ...[
                          const SizedBox(height: 16),
                          const Text('API Debug Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          // User details from API
                          if (_debugInfo!['user_details'] != null) ...[
                            Text('User ID from API: ${_debugInfo!['user_details']['id']}'),
                            Text('User Email from API: ${_debugInfo!['user_details']['email']}'),
                            Text('User Role from API: ${_debugInfo!['user_details']['role']}'),
                          ],

                          // Roles from API
                          if (_debugInfo!['roles'] != null) ...[
                            const SizedBox(height: 8),
                            const Text('User Roles:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),

                            if ((_debugInfo!['roles'] as List).isEmpty)
                              const Text('No roles found for this user'),

                            for (var role in _debugInfo!['roles'])
                              Text('Business ID: ${role['business_id']}, Role: ${role['role']}'),
                          ],
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loadBusinesses,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _switchToCustomerMode,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Go to Search'),
            ),
          ],
        ),
      ),
    );
  }

  // Build business list
  Widget _buildBusinessList() {
    return Column(
      children: [
        // Debug button to show raw API response
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              // Show dialog with raw API response
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('API Response Debug'),
                  content: SingleChildScrollView(
                    child: Text(
                      _businesses.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
            child: const Text('Debug: Show Raw API Response'),
          ),
        ),

        // Business list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _businesses.length,
            itemBuilder: (context, index) {
              final business = _businesses[index];
              return _buildBusinessCard(business);
            },
          ),
        ),
      ],
    );
  }

  // Build business card
  Widget _buildBusinessCard(Map<String, dynamic> business) {
    final businessName = business['name'] ?? 'Unknown Business';
    final businessEmail = business['email'] ?? '';
    final businessPhone = business['phone'] ?? '';
    final businessAddress = business['address'] ?? '';
    final businessCity = business['city'] ?? '';
    final businessPostcode = business['postcode'] ?? '';
    final businessImage = business['business_image'];
    final businessRole = business['role'] ?? '';

    // Format address
    final List<String> addressParts = [];
    if (businessAddress.isNotEmpty) addressParts.add(businessAddress);
    if (businessCity.isNotEmpty) addressParts.add(businessCity);
    if (businessPostcode.isNotEmpty) addressParts.add(businessPostcode);
    final formattedAddress = addressParts.join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to business detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Business management for $businessName coming soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: businessImage != null
                  ? ImageHelper.getCachedNetworkImage(
                      imageUrl: businessImage,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // Business details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      businessRole,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Business name
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Contact information
                  if (businessEmail.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: AppStyles.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            businessEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (businessPhone.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: AppStyles.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          businessPhone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppStyles.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (formattedAddress.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppStyles.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Manage button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to business detail screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Business management for $businessName coming soon!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Manage Business'),
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
}
