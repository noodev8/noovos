/*
Business Owner Landing Page
This screen shows businesses owned by the user
Allows navigation back to the normal user search/dashboard
Provides access to business management features like staff management
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/image_helper.dart';
import '../api/get_user_businesses_api.dart';
import 'business_staff_management_screen.dart';
import 'service_management_screen.dart';

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

  // Load businesses
  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to get businesses
      final result = await GetUserBusinessesApi.getUserBusinesses();

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _businesses = result['businesses'];

            // If no businesses found, set an error message
            if (_businesses.isEmpty) {
              _errorMessage = 'No businesses found for your account.';
            }
          } else {
            _errorMessage = result['message'] ?? 'Failed to load businesses.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  // Handle profile navigation
  void _handleProfile() {
    Navigator.pushNamed(context, '/profile');
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
          // Profile button
          TextButton.icon(
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text('Profile', style: TextStyle(color: Colors.white)),
            onPressed: _handleProfile,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _businesses.length,
      itemBuilder: (context, index) {
        final business = _businesses[index];
        return _buildBusinessCard(business);
      },
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
          // Navigate to staff management screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessStaffManagementScreen(
                business: business,
              ),
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

                  // Management buttons
                  Row(
                    children: [
                      // Manage Services button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to service management screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceManagementScreen(
                                  business: business,
                                ),
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
                          child: const Text('Services'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Manage Staff button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to staff management screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessStaffManagementScreen(
                                  business: business,
                                ),
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
                          child: const Text('Staff'),
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
}
