/*
Display service search results
This screen shows services based on either a search term or a selected category
Users can view service details and select a service to book
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/search_business_api.dart';
import '../api/search_category_service_api.dart';
import '../helpers/image_helper.dart';
import '../config/app_config.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Determine if we're in search mode or category mode
    _isSearchMode = widget.searchTerm != null;
    
    // Load services
    _loadServices();
  }

  // Load services based on search term or category
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSearchMode) {
        // Search mode - use search_business API
        await _loadSearchResults();
      } else if (widget.category != null) {
        // Category mode - use search_category_service API
        await _loadCategoryServices();
      } else {
        // Neither search term nor category provided
        setState(() {
          _errorMessage = 'No search criteria provided';
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

  // Load search results using search_business API
  Future<void> _loadSearchResults() async {
    try {
      // Call the API to search for businesses
      final result = await SearchBusinessApi.searchBusiness(widget.searchTerm!);

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];
        
        setState(() {
          // Check if there are results
          if (data['return_code'] == 'SUCCESS') {
            // Normalize the data to match our service card format
            _services = data['results'].map((result) {
              return {
                'service_id': result['service_id'],
                'service_name': result['service_name'],
                'business_name': result['business_name'],
                'service_description': result['service_description'],
                'service_image': result['service_image'],
                'business_profile': result['business_profile'],
                'price': result['cost'], // Map cost to price
                'city': result['city'],
                'postcode': result['postcode'],
                // Duration might not be available in search results
                'duration': null,
              };
            }).toList();
          } else {
            // No results found
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

  // Load category services using search_category_service API
  Future<void> _loadCategoryServices() async {
    try {
      // Get category ID
      final categoryId = widget.category!['id'];
      
      // Call the API to get services for this category
      final result = await SearchCategoryServiceApi.getServicesByCategory(categoryId);

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];
        
        setState(() {
          // Store the category data
          _categoryData = data['category'];
          
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

  // Build a service card
  Widget _buildServiceCard(Map<String, dynamic> service) {
    // Extract service data
    final serviceName = service['service_name'] ?? 'Unknown Service';
    final businessName = service['business_name'] ?? 'Unknown Business';
    final serviceDescription = service['service_description'] ?? '';
    final serviceImage = service['service_image'];
    final price = service['price'] ?? 0.0;
    final duration = service['duration']; // This might be null for search results
    final city = service['city'] ?? '';
    final postcode = service['postcode'] ?? '';

    // Format price as currency
    final formattedPrice = '£${price.toStringAsFixed(2)}';
    
    // Format duration if available
    final String? formattedDuration = duration != null ? '$duration mins' : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to service detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service booking coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
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
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppStyles.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                        ],
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
                color: AppStyles.primaryColor.withAlpha(25),
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
