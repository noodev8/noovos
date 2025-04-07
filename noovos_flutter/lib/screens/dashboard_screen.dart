/*
Show the dashboard screen after user login
This is the main screen of the application
Allows the user to search for businesses and services
Displays search results in a list
Allows the user to log out
*/

import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';
import '../api/search_business_api.dart';

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

  // Search state
  bool _isSearching = false;

  // Search results
  List<dynamic> _searchResults = [];

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search error message
  String? _searchErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.dispose();
    super.dispose();
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

  // Handle search
  Future<void> _handleSearch() async {
    // Get the search term
    final searchTerm = _searchController.text.trim();

    // Check if search term is empty
    if (searchTerm.isEmpty) {
      setState(() {
        _searchErrorMessage = 'Please enter a search term';
      });
      return;
    }

    // Clear previous error message
    setState(() {
      _searchErrorMessage = null;
      _isSearching = true;
    });

    try {
      // Call the search API
      final result = await SearchBusinessApi.searchBusiness(searchTerm);

      // Check if search was successful
      if (result['success']) {
        // Get the search results
        final data = result['data'];

        setState(() {
          // Check if there are results
          if (data['return_code'] == 'SUCCESS') {
            _searchResults = data['results'];
          } else {
            // No results found
            _searchResults = [];
            _searchErrorMessage = 'No results found for "$searchTerm"';
          }
          _isSearching = false;
        });
      } else {
        // Handle error
        setState(() {
          _searchResults = [];
          _searchErrorMessage = result['message'];
          _isSearching = false;
        });

        // Check if unauthorized
        if (result['return_code'] == 'UNAUTHORIZED') {
          // Redirect to login
          if (mounted) {
            // Perform logout
            await AuthHelper.logout();

            // Navigate to login if still mounted
            if (mounted) {
              // Use a separate function to avoid BuildContext across async gap warning
              _navigateToLogin();
            }
          }
        }
      }
    } catch (e) {
      // Handle error
      setState(() {
        _searchResults = [];
        _searchErrorMessage = 'An error occurred: $e';
        _isSearching = false;
      });
    }
  }

  // Clear search results
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _searchErrorMessage = null;
    });
  }

  // Navigate to login screen
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
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

                      // Search section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search heading
                            const Text(
                              'Find Salons & Services',
                              style: AppStyles.subheadingStyle,
                            ),
                            const SizedBox(height: 15),

                            // Search description
                            const Text(
                              'Search for salons and services near you',
                              style: AppStyles.bodyStyle,
                            ),
                            const SizedBox(height: 20),

                            // Search input and button
                            Row(
                              children: [
                                // Search input field
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: AppStyles.inputDecoration(
                                      'Search',
                                      hint: 'e.g. massage, haircut, spa',
                                      prefixIcon: const Icon(Icons.search),
                                    ),
                                    onSubmitted: (_) => _handleSearch(),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Search button
                                ElevatedButton(
                                  onPressed: _isSearching ? null : _handleSearch,
                                  style: AppStyles.primaryButtonStyle,
                                  child: _isSearching
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Search'),
                                ),
                              ],
                            ),

                            // Error message
                            if (_searchErrorMessage != null) ...[
                              const SizedBox(height: 15),
                              Text(
                                _searchErrorMessage!,
                                style: const TextStyle(
                                  color: AppStyles.errorColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Search results section
                      if (_searchResults.isNotEmpty) ...[
                        // Results heading with clear button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search Results',
                              style: AppStyles.subheadingStyle,
                            ),
                            TextButton.icon(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppStyles.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Results list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            // Get the result
                            final result = _searchResults[index];

                            // Build the result card
                            return _buildSearchResultCard(result);
                          },
                        ),
                      ],

                      const SizedBox(height: 30),

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

  // Build search result card
  Widget _buildSearchResultCard(Map<String, dynamic> result) {
    // Extract data from result
    final serviceName = result['service_name'] ?? 'Unknown Service';
    final businessName = result['business_name'] ?? 'Unknown Business';
    final serviceDescription = result['service_description'] ?? 'No description available';
    final city = result['city'] ?? 'Unknown';
    final postcode = result['postcode'] ?? '';
    final serviceImage = result['service_image'];
    final businessProfile = result['business_profile'];

    // Handle cost which should be a number from the API, but we handle all cases for robustness
    // The API has been updated to ensure cost is returned as a number, not a string
    String formattedPrice;
    final cost = result['cost'];

    if (cost == null) {
      // Default price if cost is null
      formattedPrice = '£0.00';
    } else if (cost is String) {
      // If cost is already a string, try to parse it as double first
      try {
        final costDouble = double.parse(cost);
        formattedPrice = '£${costDouble.toStringAsFixed(2)}';
      } catch (e) {
        // If parsing fails, just use the string directly with £ prefix
        formattedPrice = '£$cost';
      }
    } else if (cost is num) {
      // If cost is a number (int or double), format it
      formattedPrice = '£${cost.toStringAsFixed(2)}';
    } else {
      // Fallback for any other type
      formattedPrice = '£${cost.toString()}';
    }

    // Format the location
    final location = city + (postcode.isNotEmpty ? ', $postcode' : '');

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service and business name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image or placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: serviceImage != null && serviceImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(serviceImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: serviceImage == null || serviceImage.isEmpty
                      ? const Icon(
                          Icons.spa,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
                const SizedBox(width: 15),

                // Service and business details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Business name
                      Row(
                        children: [
                          // Business profile image
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: businessProfile != null && businessProfile.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(businessProfile),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: businessProfile == null || businessProfile.isEmpty
                                ? const Icon(
                                    Icons.business,
                                    size: 12,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 5),

                          // Business name text
                          Expanded(
                            child: Text(
                              businessName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppStyles.secondaryTextColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    // Use a lighter version of the primary color
                    color: AppStyles.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppStyles.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            // Description
            if (serviceDescription.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                serviceDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppStyles.textColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // View details button
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Service details navigation will be implemented in a future update
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Service details coming soon!'),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
