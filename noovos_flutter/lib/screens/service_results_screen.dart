/*
Display service search results
This screen shows services based on either a search term or a selected category
Users can view service details and select a service to book
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/search_service_api.dart';
import '../helpers/image_helper.dart';
import '../helpers/cart_helper.dart';
import '../helpers/auth_helper.dart';
import 'service_details_screen.dart';
import 'staff_selection_screen.dart';


class ServiceResultsScreen extends StatefulWidget {
  // Search parameters - either searchTerm or category should be provided
  final String? searchTerm;
  final Map<String, dynamic>? category;
  final String? location;

  // Constructor
  const ServiceResultsScreen({
    Key? key,
    this.searchTerm,
    this.category,
    this.location,
  }) : super(key: key);

  @override
  State<ServiceResultsScreen> createState() => _ServiceResultsScreenState();
}

class _ServiceResultsScreenState extends State<ServiceResultsScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Services list
  List<dynamic> _services = [];

  // Search mode
  late bool _isSearchMode;

  // Category data (if in category mode)
  Map<String, dynamic>? _categoryData;

  // Login status
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Determine if we're in search mode or category mode
    _isSearchMode = widget.searchTerm != null;

    // Check login status
    _checkLoginStatus();

    // Load services
    _loadServices();
  }

  // Check if user is logged in
  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await AuthHelper.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    } catch (e) {
      // Handle error silently
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  // Handle profile navigation
  void _handleProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  // Handle login navigation
  void _handleLogin() {
    Navigator.pushNamed(context, '/login');
  }

  // Load services based on search term or category
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine which parameters to use based on what was provided
      final String? searchTerm = widget.searchTerm;
      final String? location = widget.location;
      final int? categoryId = widget.category != null ? widget.category!['id'] : null;

      // Call the unified search_service API
      final result = await SearchServiceApi.searchServices(
        searchTerm: searchTerm,
        location: location,
        categoryId: categoryId,
        page: 1,
        limit: 20,
      );

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];

        setState(() {
          // Store category data if we're in category mode
          if (widget.category != null) {
            _categoryData = widget.category;
          }

          // Check if there are services
          if (data['return_code'] == 'SUCCESS') {
            _services = data['services'];
          } else {
            // No services found
            _services = [];
          }
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _errorMessage = result['message'];
          _services = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _services = [];
        _isLoading = false;
      });
    }
  }

  // Navigate directly to staff selection screen
  void _checkServiceStaff(Map<String, dynamic> service) {
    // Navigate directly to staff selection screen with a material page route
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StaffSelectionScreen(
          serviceDetails: service,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Build a service card
  Widget _buildServiceCard(Map<String, dynamic> service) {
    // Extract service data
    final serviceId = service['service_id'] ?? 0;
    final serviceName = service['service_name'] ?? 'Unknown Service';
    final businessId = service['business_id'] ?? 0;
    final businessName = service['business_name'] ?? 'Unknown Business';
    final serviceDescription = service['service_description'] ?? '';
    final serviceImage = service['service_image'];
    // Handle price/cost which might be a string or a number
    var priceValue = service['cost'] ?? 0.0;
    // Convert to double if it's a string
    final double price = priceValue is String ? double.tryParse(priceValue) ?? 0.0 : priceValue.toDouble();

    final duration = service['duration']; // This might be null for search results
    final city = service['city'] ?? '';
    final postcode = service['postcode'] ?? '';

    // Format price as currency
    final formattedPrice = '£${price.toStringAsFixed(2)}';

    // Format duration if available
    final String? formattedDuration = duration != null ? '$duration mins' : null;

    // Check if service is in cart
    bool isInCart = CartHelper.isInCart(serviceId);

    // Check if service can be added to cart based on business restrictions
    bool canAddBasedOnBusiness = businessId > 0 ? CartHelper.canAddToCart(businessId) : true;

    // Check if cart is full (only matters if not already in cart)
    bool isCartFull = !isInCart && CartHelper.isCartFull();

    // Service can be added only if it passes both checks
    bool canAddToCart = canAddBasedOnBusiness && !isCartFull;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Make the card clickable
          InkWell(
            onTap: () {
              // Navigate to service detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailsScreen(
                    serviceId: serviceId,
                    serviceData: service,
                  ),
                ),
              ).then((_) {
                // Refresh the UI when returning from details screen
                setState(() {});
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: serviceImage != null
                      ? ImageHelper.getCachedNetworkImage(
                          imageUrl: serviceImage,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.spa,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Service details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business name
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppStyles.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Service name
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Service description
                      if (serviceDescription.isNotEmpty) ...[
                        Text(
                          serviceDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppStyles.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Price, duration and location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.primaryColor,
                            ),
                          ),

                          // Duration (if available)
                          if (formattedDuration != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppStyles.secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDuration,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppStyles.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),

                          // Location
                          if (city.isNotEmpty || postcode.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppStyles.secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  city.isNotEmpty && postcode.isNotEmpty
                                      ? '$city, $postcode'
                                      : city.isNotEmpty
                                          ? city
                                          : postcode,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppStyles.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // See more button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to service detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsScreen(
                            serviceId: serviceId,
                            serviceData: service,
                          ),
                        ),
                      ).then((_) {
                        // Refresh the UI when returning from details screen
                        setState(() {});
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppStyles.primaryColor,
                      side: const BorderSide(color: AppStyles.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('See More'),
                  ),
                ),
                const SizedBox(width: 12),

                // Add to cart button
                Expanded(
                  child: isInCart
                      ? OutlinedButton(
                          onPressed: () async {
                            // Remove from cart
                            await CartHelper.removeFromCart(serviceId);

                            if (mounted) {
                              setState(() {
                                // Force refresh of cart status
                                isInCart = CartHelper.isInCart(serviceId);
                                canAddToCart = businessId > 0 ? CartHelper.canAddToCart(businessId) : true;
                              });

                              // Show snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Service removed from cart'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppStyles.errorColor,
                            side: const BorderSide(color: AppStyles.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Remove'),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            // Check if service can be added to cart
                            if (!canAddToCart) {
                              // Check if cart is full
                              if (CartHelper.isCartFull() && !isInCart) {
                                // Show cart full warning dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cart is Full'),
                                    content: Text(
                                      'Your cart already has the maximum of ${CartHelper.maxCartItems} items. '
                                      'Please remove an item before adding a new one, or clear your cart to start over.\n\n'
                                      'Would you like to clear your cart and continue with this service instead?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Clear cart
                                          CartHelper.clearCart();
                                          Navigator.pop(context);

                                          // Check if the service has staff members
                                          _checkServiceStaff(service);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppStyles.primaryColor,
                                        ),
                                        child: const Text('Clear Cart & Continue'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              } else {
                                // Show business restriction warning dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cannot Continue'),
                                    content: Text(
                                      'You already have services from ${CartHelper.getCurrentBusinessName() ?? 'another business'} in your cart. '
                                      'You can only book services from one business at a time.\n\n'
                                      'Would you like to clear your cart and continue with this service instead?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Clear cart
                                          CartHelper.clearCart();
                                          Navigator.pop(context);

                                          // Check if the service has staff members
                                          _checkServiceStaff(service);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppStyles.primaryColor,
                                        ),
                                        child: const Text('Clear Cart & Continue'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                            }

                            // Check if the service has staff members
                            _checkServiceStaff(service);
                            return;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the header based on search mode
  Widget _buildHeader() {
    if (_isSearchMode) {
      // Search mode header
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search term
          Text(
            'Results for "${widget.searchTerm}"',
            style: AppStyles.headingStyle,
          ),

          // Location if provided
          if (widget.location != null && widget.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppStyles.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'in ${widget.location}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else if (_categoryData != null) {
      // Category mode header
      final categoryName = _categoryData!['name'] ?? 'Unknown Category';
      final categoryDescription = _categoryData!['description'];
      final categoryIconUrl = _categoryData!['icon_url'];

      return Row(
        children: [
          // Category icon
          if (categoryIconUrl != null)
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                // Light version of primary color
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ImageHelper.getCachedNetworkImage(
                  imageUrl: categoryIconUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.category,
                    color: AppStyles.primaryColor,
                    size: 30,
                  ),
                ),
              ),
            ),

          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: AppStyles.headingStyle,
                ),
                if (categoryDescription != null && categoryDescription.isNotEmpty)
                  Text(
                    categoryDescription,
                    style: AppStyles.bodyStyle,
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Fallback header
      return const Text(
        'Service Results',
        style: AppStyles.headingStyle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the app bar title
    final String appBarTitle = _isSearchMode
        ? 'Search Results'
        : widget.category != null
            ? widget.category!['name'] ?? 'Category Services'
            : 'Service Results';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Profile or Login button
          _isLoggedIn
              ? TextButton.icon(
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text('Profile', style: TextStyle(color: Colors.white)),
                  onPressed: _handleProfile,
                )
              : TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Login', style: TextStyle(color: Colors.white)),
                  onPressed: _handleLogin,
                ),

          // Cart icon
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to cart screen while preserving the search results page in the stack
                  Navigator.pushNamed(context, '/cart').then((_) {
                    // Refresh the state when returning from cart screen
                    setState(() {});
                  });
                },
                tooltip: 'View Cart',
              ),

              // Cart badge
              if (CartHelper.getCartCount() > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${CartHelper.getCartCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
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
                        Text(
                          'Error loading services',
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
                          onPressed: _loadServices,
                          style: AppStyles.primaryButtonStyle,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (search term or category)
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Services count
                      Text(
                        _services.isEmpty
                            ? 'No services available'
                            : '${_services.length} ${_services.length == 1 ? 'service' : 'services'} available',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 16),

                      // Services list
                      if (_services.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSearchMode
                                      ? 'No results found for "${widget.searchTerm}"'
                                      : 'No services found for this category',
                                  style: AppStyles.subheadingStyle.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSearchMode
                                      ? 'Try a different search term or browse by category'
                                      : 'Try selecting a different category or search for a specific service',
                                  style: AppStyles.bodyStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(_services[index]);
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
