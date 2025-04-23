/*
Display detailed information about a service
This screen shows complete details for a selected service
Users can view service information and add the service to their cart
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_service_api.dart';
import '../api/get_service_staff_api.dart';
import '../helpers/image_helper.dart';
import '../helpers/cart_helper.dart';

import 'staff_selection_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  // Service ID to display
  final int serviceId;

  // Optional service data if already available
  final Map<String, dynamic>? serviceData;

  // Constructor
  const ServiceDetailsScreen({
    Key? key,
    required this.serviceId,
    this.serviceData,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Service details
  Map<String, dynamic>? _serviceDetails;

  // Is service in cart
  bool _isInCart = false;

  // Can add to cart (based on business restrictions)
  bool _canAddToCart = true;

  // Current business in cart (if any)
  String? _currentBusinessInCart;

  @override
  void initState() {
    super.initState();

    // If service data is provided, use it
    if (widget.serviceData != null) {
      _serviceDetails = widget.serviceData;
      _isLoading = false;

      // Check if service is in cart
      _checkIfInCart();
    } else {
      // Load service details
      _loadServiceDetails();
    }
  }

  // Check if service is in cart and if it can be added
  void _checkIfInCart() {
    if (_serviceDetails == null) return;

    // Check if service is in cart
    _isInCart = CartHelper.isInCart(widget.serviceId);

    // Get business ID from service details
    final businessId = _serviceDetails!['business_id'] ?? 0;

    // Check if service can be added to cart (based on business restrictions)
    _canAddToCart = businessId > 0 ? CartHelper.canAddToCart(businessId) : true;

    // Get current business in cart (if any)
    _currentBusinessInCart = CartHelper.getCurrentBusinessName();
  }

  // Load service details from API
  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API to get service details
      final result = await GetServiceApi.getService(widget.serviceId);

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];

        setState(() {
          _serviceDetails = data['service'];
          _isLoading = false;

          // Check if service is in cart
          _checkIfInCart();
        });
      } else {
        // Handle error
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // Add service to cart
  void _addToCart() {
    if (_serviceDetails == null) return;

    // Check if we can add to cart
    if (_canAddToCart) {
      // If we can add to cart, proceed directly
      // First check if the service has staff members
      _checkServiceStaff();
    } else {
      // If we can't add to cart, show the business restriction dialog
      _showBusinessRestrictionDialog();
    }
  }

  // Check if the service has staff members
  void _checkServiceStaff() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get service ID
      final int serviceId = _serviceDetails!['service_id'];

      // Call the API to get staff list
      // We don't filter by staff ID here because we want to show all staff members
      final result = await GetServiceStaffApi.getServiceStaff(serviceId);

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];
        final staffList = data['staff'] as List<dynamic>;

        if (staffList.isEmpty) {
          // If there are no staff members, add to cart directly with 'Any Staff'
          _addToCartWithAnyStaff();
        } else {
          // If there are staff members, navigate to staff selection screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffSelectionScreen(
                  serviceDetails: _serviceDetails!,
                ),
              ),
            ).then((_) {
              // Check if the service is in the cart after returning from the staff selection screen
              if (mounted) {
                setState(() {
                  _isInCart = CartHelper.isInCart(widget.serviceId);
                  _canAddToCart = true; // We just added it, so it's compatible
                });
              }
            });
          }
        }
      } else {
        // If the request failed, add to cart directly with 'Any Staff'
        _addToCartWithAnyStaff();
      }
    } catch (e) {
      // If there was an error, add to cart directly with 'Any Staff'
      setState(() {
        _isLoading = false;
      });
      _addToCartWithAnyStaff();
    }
  }

  // Add service to cart with 'Any Staff'
  void _addToCartWithAnyStaff() {
    // Create cart item with 'Any Staff'
    final cartItem = CartItem(
      serviceId: _serviceDetails!['service_id'],
      serviceName: _serviceDetails!['service_name'],
      businessId: _serviceDetails!['business_id'] ?? 0,
      businessName: _serviceDetails!['business_name'],
      price: _serviceDetails!['price'] != null
          ? (_serviceDetails!['price'] is String
              ? double.tryParse(_serviceDetails!['price']) ?? 0.0
              : _serviceDetails!['price'] is num
                  ? _serviceDetails!['price'].toDouble()
                  : 0.0)
          : 0.0,
      serviceImage: _serviceDetails!['service_image'],
      duration: _serviceDetails!['duration'],
      staffId: null, // Any staff
      staffName: null, // Any staff
    );

    // Add to cart
    CartHelper.addToCart(cartItem).then((success) {
      if (success && mounted) {
        // Update state
        setState(() {
          _isInCart = true;
          _canAddToCart = true; // We just added it, so it's compatible
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_serviceDetails!['service_name']} added to cart'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to cart screen
        Navigator.pushNamed(context, '/cart');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add service to cart'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Show dialog for business restriction
  void _showBusinessRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Add to Cart'),
        content: Text(
          'You already have services from ${CartHelper.getCurrentBusinessName() ?? 'another business'} in your cart. '
          'You can only book services from one business at a time.\n\n'
          'Would you like to clear your cart and add this service instead?'
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
              // Clear cart and close dialog
              CartHelper.clearCart();
              Navigator.pop(context);

              // Check if the service has staff members
              _checkServiceStaff();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.primaryColor,
            ),
            child: const Text('Clear Cart & Add'),
          ),
        ],
      ),
    );
  }

  // Remove service from cart
  void _removeFromCart() {
    // Remove from cart
    CartHelper.removeFromCart(widget.serviceId);

    // Update state
    setState(() {
      _isInCart = false;
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service removed from cart'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_serviceDetails != null
            ? _serviceDetails!['service_name']
            : 'Service Details'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
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
                          'Error loading service details',
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
                          onPressed: _loadServiceDetails,
                          style: AppStyles.primaryButtonStyle,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildServiceDetails(),
      bottomNavigationBar: _isLoading || _errorMessage != null || _serviceDetails == null
          ? null
          : _buildBottomBar(),
    );
  }

  // Build service details content
  Widget _buildServiceDetails() {
    if (_serviceDetails == null) {
      return const Center(
        child: Text('No service details available'),
      );
    }

    // Extract service data
    final serviceName = _serviceDetails!['service_name'] ?? 'Unknown Service';
    final businessName = _serviceDetails!['business_name'] ?? 'Unknown Business';
    final serviceDescription = _serviceDetails!['service_description'] ?? '';
    final serviceImage = _serviceDetails!['service_image'];
    final businessImage = _serviceDetails!['business_image'];

    // Handle price/cost which might be a string or a number
    var priceValue = _serviceDetails!['price'] ?? 0.0;
    // Convert to double if it's a string
    final double price = priceValue is String ? double.tryParse(priceValue) ?? 0.0 : priceValue.toDouble();

    final duration = _serviceDetails!['duration'] ?? 0;
    final currency = _serviceDetails!['currency'] ?? 'GBP';
    final categoryName = _serviceDetails!['category_name'] ?? '';
    final city = _serviceDetails!['city'] ?? '';
    final postcode = _serviceDetails!['postcode'] ?? '';
    final address = _serviceDetails!['address'] ?? '';

    // Format price as currency
    final formattedPrice = currency == 'GBP' ? '£${price.toStringAsFixed(2)}' : '${price.toStringAsFixed(2)} $currency';

    // Format duration
    final formattedDuration = '$duration mins';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image
          if (serviceImage != null)
            SizedBox(
              width: double.infinity,
              height: 200,
              child: ImageHelper.getCachedNetworkImage(
                imageUrl: serviceImage,
                fit: BoxFit.cover,
                errorWidget: const Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            )
          else if (businessImage != null)
            SizedBox(
              width: double.infinity,
              height: 200,
              child: ImageHelper.getCachedNetworkImage(
                imageUrl: businessImage,
                fit: BoxFit.cover,
                errorWidget: const Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 64,
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
                    fontSize: 16,
                    color: AppStyles.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // Service name
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                if (categoryName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price and duration
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formattedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Duration
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDuration,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description heading
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Service description
                if (serviceDescription.isNotEmpty)
                  Text(
                    serviceDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppStyles.textColor,
                    ),
                  )
                else
                  const Text(
                    'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppStyles.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 24),

                // Location heading
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Location details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 20,
                      color: AppStyles.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address.isNotEmpty
                            ? '$address, $city, $postcode'
                            : '$city, $postcode',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppStyles.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build bottom bar with action buttons
  Widget _buildBottomBar() {
    // Check if we need to show a business restriction warning
    final bool showBusinessWarning = !_canAddToCart && !_isInCart;
    final String? currentBusiness = _currentBusinessInCart;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show warning if service is from a different business
        if (showBusinessWarning && currentBusiness != null && currentBusiness.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You already have services from $currentBusiness in your cart. '
                    'You can only book services from one business at a time.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: AppStyles.secondaryButtonStyle,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),

              // Add to cart or remove from cart button
              Expanded(
                flex: 2,
                child: _isInCart
                    ? ElevatedButton(
                        onPressed: _removeFromCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Remove from Cart'),
                      )
                    : ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canAddToCart
                              ? AppStyles.primaryColor
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _canAddToCart
                            ? const Text('Add to Cart')
                            : const Text('Replace Cart Items'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
