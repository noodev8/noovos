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
import '../helpers/staff_invitation_helper.dart';

import '../api/get_categories_api.dart';
import '../helpers/image_helper.dart';
import '../helpers/cloudinary_helper.dart';
import '../screens/service_results_screen.dart';
import '../screens/staff_bookings_screen.dart';
import '../screens/comprehensive_bookings_screen.dart';

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

  // Staff state - indicates if user is staff for any business
  bool _isStaff = false;

  // Categories state
  bool _isLoadingCategories = false;
  List<dynamic> _categories = [];
  String? _categoriesErrorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCategories();
    _checkForInvitations();
  }

  // Check for staff invitations
  Future<void> _checkForInvitations() async {
    // Wait a moment to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user is logged in
    final isLoggedIn = await AuthHelper.isLoggedIn();

    // If logged in and the widget is still mounted, check for invitations
    if (isLoggedIn && mounted) {
      await StaffInvitationHelper.checkForInvitations(context);
    }
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
      // Enhanced error handling for categories
      String errorMessage;
      if (e.toString().contains('errno = 113') || e.toString().contains('No route to host')) {
        errorMessage = 'Network connection error. Please check server availability.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Server is not responding. Please check if the server is running.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your connection.';
      } else {
        errorMessage = 'Network error: $e';
      }

      setState(() {
        _categories = [];
        _categoriesErrorMessage = errorMessage;
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

  // Check if user is logged in and if they are a business owner or staff
  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await AuthHelper.isLoggedIn();
      bool isBusinessOwner = false;
      bool isStaff = false;

      // If logged in, check if user is a business owner or staff
      if (isLoggedIn) {
        isBusinessOwner = await AuthHelper.isBusinessOwner();
        isStaff = await AuthHelper.isStaff();
      }

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isBusinessOwner = isBusinessOwner;
        _isStaff = isStaff;
      });
    } catch (e) {
      // Handle error silently
      setState(() {
        _isLoggedIn = false;
        _isBusinessOwner = false;
        _isStaff = false;
      });
    }
  }

  // Public method to refresh login status (can be called from other screens)
  Future<void> refreshLoginStatus() async {
    await _checkLoginStatus();
  }

  // Handle profile navigation
  void _handleProfile() {
    Navigator.pushNamed(context, '/profile');
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

  // Navigate to staff bookings screen
  // This is the key method that shows staff their bookings, indicating their business connection
  void _navigateToStaffBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StaffBookingsScreen(),
      ),
    );
  }

  // Navigate to comprehensive bookings screen
  // This method shows all user bookings (customer bookings, staff appointments, business management)
  void _navigateToBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComprehensiveBookingsScreen(),
      ),
    );
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header section with gradient background
          _buildGradientHeader(isTablet),
          // Main content section
          Expanded(
            child: _buildMainContent(isTablet),
          ),
        ],
      ),
    );
  }

  // Build the gradient header section
  Widget _buildGradientHeader(bool isTablet) {
    final headerHeight = isTablet ? 200.0 : 160.0;

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF4F46E5), // Blue
            Color(0xFF7C3AED), // Purple
            Color(0xFFEC4899), // Pink
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Navigation buttons in top right
            Positioned(
              top: 10,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show business owner button if user is a business owner
                  if (_isLoggedIn && _isBusinessOwner)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.business, color: Colors.white, size: 18),
                        label: const Text('My Business', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: _switchToBusinessOwnerMode,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),

                  // Show bookings button for ALL logged-in users
                  if (_isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                        label: const Text('Bookings', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: _navigateToBookings,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),

                  // Show profile or login button based on login status
                  _isLoggedIn
                      ? TextButton.icon(
                          icon: const Icon(Icons.person, color: Colors.white, size: 18),
                          label: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: _handleProfile,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.login, color: Colors.white, size: 18),
                          label: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: _handleLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                ],
              ),
            ),
            // Main content centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  _buildLogo(isTablet),
                  const SizedBox(height: 12),
                  // App title
                  Text(
                    'noovos',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
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

  // Build the logo/icon
  Widget _buildLogo(bool isTablet) {
    final logoSize = isTablet ? 60.0 : 48.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/noovos_app_icon.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Build the main content section
  Widget _buildMainContent(bool isTablet) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 30 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search section
                _buildSearchSection(isTablet),
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
            );
  }

  // Build search section
  Widget _buildSearchSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search heading
          Text(
            'Find Salons & Services',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Search description
          Text(
            'Search for salons and services near you',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Service search field
          _buildCleanTextField(
            controller: _searchController,
            hintText: 'Service or Salon (e.g. massage, haircut, spa)',
            prefixIcon: Icons.search,
            onSubmitted: (_) => _handleSearch(),
          ),
          const SizedBox(height: 16),

          // Location search field
          _buildCleanTextField(
            controller: _locationController,
            hintText: 'Location (Town, City or Postcode - optional)',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Search error message
          if (_searchErrorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _searchErrorMessage!,
                      style: TextStyle(color: Colors.red[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build clean text field matching the design
  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[500]) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      imageUrl: serviceImage != null
                          ? CloudinaryHelper.getCloudinaryUrl(serviceImage)
                          : null,
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
                                imageUrl: businessProfile != null
                                    ? CloudinaryHelper.getCloudinaryUrl(businessProfile)
                                    : null,
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
