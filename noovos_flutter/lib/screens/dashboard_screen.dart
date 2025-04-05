/*
Show the dashboard screen after user login
This is the main screen of the application
Allows the user to log out
*/

import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // User data
  Map<String, dynamic>? _userData;
  
  // Loading state
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  // Load user data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = await AuthHelper.getUserData();
      
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }
  
  // Handle logout
  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await AuthHelper.logout();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Debug print to check development mode
    print('Development mode: ${AppConfig.developmentMode}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Only show settings button in development mode
          if (AppConfig.developmentMode)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              tooltip: 'Settings',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userData == null
              ? const Center(
                  child: Text('No user data found'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      Text(
                        'Welcome, ${_userData!['name']}!',
                        style: AppStyles.headingStyle,
                      ),
                      const SizedBox(height: 20),
                      
                      // User info card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Profile',
                              style: AppStyles.subheadingStyle,
                            ),
                            const SizedBox(height: 15),
                            _buildProfileItem('ID', _userData!['id'].toString()),
                            _buildProfileItem('Name', _userData!['name']),
                            _buildProfileItem('Email', _userData!['email']),
                            _buildProfileItem('Account Level', _userData!['account_level']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Dashboard content
                      const Text(
                        'Dashboard Content',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.cardDecoration,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Noovos!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'This is a placeholder for the dashboard content. '
                              'You can add your own content here.',
                              style: AppStyles.bodyStyle,
                            ),
                          ],
                        ),
                      ),
                      
                      // Development settings button
                      if (AppConfig.developmentMode) ...[
                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Developer Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
  
  // Build profile item
  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppStyles.secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}
