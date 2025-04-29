/*
Show the dashboard/search screen
This is the main screen of the application
Allows users to search for businesses and services without requiring login
Displays search results in a list
Provides option to login for booking services
*/

import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';

import '../api/get_categories_api.dart';
import '../helpers/image_helper.dart';
import '../screens/service_results_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Loading state
  bool _isLoading = false;

  // Search state
  bool _isSearching = false;

  // Search results
  List<dynamic> _searchResults = [];

  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Search error message
  String? _searchErrorMessage;

  // Login state
  bool _isLoggedIn = false;

  // Business owner state
  bool _isBusinessOwner = false;

  // Categories state
  bool _isLoadingCategories = false;
  List<dynamic> _categories = [];
  String? _categoriesErrorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCategories();
  }

  // Load categories
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesErrorMessage = null;
    });

    try {
      // Call the API to get categories
      final result = await GetCategoriesApi.getCategories();

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];

        setState(() {
          // Check if there are categories
          if (data['return_code'] == 'SUCCESS') {
            _categories = data['categories'];
          } else {
            // No categories found
            _categories = [];
          }
          _isLoadingCategories = false;
        });
      } else {
        // Handle error
        setState(() {
          _categories = [];
          _categoriesErrorMessage = result['message'];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _categories = [];
        _categoriesErrorMessage = 'An error occurred: $e';
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Check if user is logged in and if they are a business owner
  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await AuthHelper.isLoggedIn();
      bool isBusinessOwner = false;

      // If logged in, check if user is a business owner
      if (isLoggedIn) {
        isBusinessOwner = await AuthHelper.isBusinessOwner();
      }

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isBusinessOwner = isBusinessOwner;
      });
    } catch (e) {
      // Handle error silently
      setState(() {
        _isLoggedIn = false;
        _isBusinessOwner = false;
      });
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
  void _handleSearch() {
    // Get the search term and location
    final searchTerm = _searchController.text.trim();
    final location = _locationController.text.trim();

    // Check if search term is empty
    if (searchTerm.isEmpty) {
      setState(() {
        _searchErrorMessage = 'Please enter a service or salon name';
      });
      return;
    }

    // Clear previous error message
    setState(() {
      _searchErrorMessage = null;
      _isSearching = false; // Reset search state
    });

    // Navigate to service results screen with search term and location
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceResultsScreen(
          searchTerm: searchTerm,
          location: location.isNotEmpty ? location : null,
        ),
      ),
    );
  }

  // Clear search results
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _searchErrorMessage = null;
    });
  }



  // Handle login
  void _handleLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Switch to business owner mode
  void _switchToBusinessOwnerMode() {
    Navigator.pushReplacementNamed(context, '/business_owner');
  }

  // Navigate to service results screen with category
  void _navigateToCategoryServices(Map<String, dynamic> category) {
    // Get the current search term and location if any
    final searchTerm = _searchController.text.trim();
    final location = _locationController.text.trim();

    // Navigate to service results screen with category
    // If search term is provided, it will be used along with the category
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceResultsScreen(
          category: category,
          searchTerm: searchTerm.isNotEmpty ? searchTerm : null,
          location: location.isNotEmpty ? location : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Noovos'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Show business owner button if user is a business owner
          if (_isLoggedIn && _isBusinessOwner)
            TextButton.icon(
              icon: const Icon(Icons.business, color: Colors.white),
              label: const Text('My Business', style: TextStyle(color: Colors.white)),
              onPressed: _switchToBusinessOwnerMode,
            ),

          // Show login or logout button based on login status
          _isLoggedIn
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleLogout,
                  tooltip: 'Logout',
                )
              : TextButton.icon(
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text('Profile', style: TextStyle(color: Colors.white)),
                  onPressed: _handleLogin,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                        // Service search field
                        TextField(
                          controller: _searchController,
                          decoration: AppStyles.inputDecoration(
                            'Service or Salon',
                            hint: 'e.g. massage, haircut, spa, salon name',
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _handleSearch(),
                        ),
                        const SizedBox(height: 15),

                        // Location search field
                        TextField(
                          controller: _locationController,
                          decoration: AppStyles.inputDecoration(
                            'Location',
                            hint: 'Town, City or Postcode (optional)',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Search button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
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

                  // Categories section
                  if (_isLoadingCategories) ...[
                    // Loading indicator
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_categoriesErrorMessage != null) ...[
                    // Error message
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppStyles.errorColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStyles.errorColor.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppStyles.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Error loading categories: $_categoriesErrorMessage',
                              style: const TextStyle(
                                color: AppStyles.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_categories.isNotEmpty) ...[
                    // Categories heading
                    const Text(
                      'Browse by Category',
                      style: AppStyles.subheadingStyle,
                    ),
                    const SizedBox(height: 15),

                    // Categories description
                    const Text(
                      'Select a category to find services',
                      style: AppStyles.bodyStyle,
                    ),
                    const SizedBox(height: 20),

                    // Categories horizontal list
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(_categories[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

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


                    ],
                  ),
                ),
    );
  }

  // Build category card
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    // Extract data from category
    final categoryName = category['name'] ?? 'Unknown Category';
    final categoryDescription = category['description'] ?? '';
    final categoryImage = category['icon_url']; // This might be null

    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        // Navigate to category services screen when tapped
        onTap: () => _navigateToCategoryServices(category),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 130,
          height: 180,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: categoryImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: ImageHelper.getCachedNetworkImage(
                        imageUrl: categoryImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(
                          Icons.category,
                          color: AppStyles.primaryColor,
                          size: 30,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.category,
                      color: AppStyles.primaryColor,
                      size: 30,
                    ),
              ),
              const SizedBox(height: 10),

              // Category name
              Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Category description (if available)
              if (categoryDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  categoryDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppStyles.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: ImageHelper.getCachedNetworkImage(
                      imageUrl: serviceImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                      errorWidget: const Center(
                        child: Icon(
                          Icons.spa,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
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
                          ClipOval(
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.grey[200],
                              child: ImageHelper.getCachedNetworkImage(
                                imageUrl: businessProfile,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                placeholder: Center(
                                  child: SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                errorWidget: const Center(
                                  child: Icon(
                                    Icons.business,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
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
