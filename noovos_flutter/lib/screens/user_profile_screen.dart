/*
User Profile Screen
Displays user profile information with options to logout, delete account, and register business
Provides comprehensive account management functionality
*/

import 'package:flutter/material.dart';
import '../api/get_user_profile_api.dart';
import '../api/delete_user_data_api.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Loading state
  bool _isLoading = true;

  // User data
  Map<String, dynamic>? _userData;

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await GetUserProfileApi.getUserProfile();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          setState(() {
            _userData = result['user'];
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load profile';
          });

          // If unauthorized, redirect to login
          if (result['return_code'] == 'UNAUTHORIZED') {
            _handleLogout();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while loading your profile';
        });
      }
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    // Clear authentication data
    await AuthHelper.logout();

    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Show delete account confirmation dialog
  void _showDeleteAccountDialog() {
    final confirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action will permanently delete all your data and cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('This includes:'),
              const Text('• Your account information'),
              const Text('• All bookings and history'),
              const Text('• Business associations'),
              const Text('• All personal data'),
              const SizedBox(height: 16),
              const Text(
                'To confirm, please type "DELETE_MY_DATA" below:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  hintText: 'DELETE_MY_DATA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteAccount(confirmationController.text);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  // Handle account deletion
  Future<void> _handleDeleteAccount(String confirmation) async {
    if (confirmation != 'DELETE_MY_DATA') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type "DELETE_MY_DATA" exactly to confirm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await DeleteUserDataApi.deleteUserData(confirmation);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result['success']) {
          // Clear auth and redirect to login
          await AuthHelper.logout();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while deleting account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigate to business registration
  void _navigateToBusinessRegistration() {
    Navigator.pushNamed(context, '/register-business');
  }

  // Show support contact dialog
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help? Contact our support team:'),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email, color: AppStyles.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'noodev8@gmail.com',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'We typically respond within 24 hours.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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
        title: const Text('Profile'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildProfileView(),
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
              onPressed: _loadUserProfile,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build profile view
  Widget _buildProfileView() {
    if (_userData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppStyles.primaryColor,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_userData!['first_name']} ${_userData!['last_name']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userData!['email'],
                  style: AppStyles.subheadingStyle,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _userData!['email_verified'] == true
                          ? Icons.verified
                          : Icons.warning,
                      color: _userData!['email_verified'] == true
                          ? Colors.green
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userData!['email_verified'] == true
                          ? 'Email Verified'
                          : 'Email Not Verified',
                      style: TextStyle(
                        color: _userData!['email_verified'] == true
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Mobile', _userData!['mobile'] ?? 'Not provided'),
                _buildDetailRow('Account Level', _userData!['account_level'] ?? 'Standard'),
                _buildDetailRow('Member Since', _formatDate(_userData!['created_at'])),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Account Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Logout button
                ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: AppStyles.primaryButtonStyle,
                ),
                const SizedBox(height: 12),

                // Contact support button
                OutlinedButton.icon(
                  onPressed: _showSupportDialog,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppStyles.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Delete account button
                OutlinedButton.icon(
                  onPressed: _showDeleteAccountDialog,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Personal Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Business registration
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Business',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Want to offer services through our platform?',
                  style: AppStyles.subheadingStyle,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToBusinessRegistration,
                  icon: const Icon(Icons.business),
                  label: const Text('Register a Business'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Format date for display
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
