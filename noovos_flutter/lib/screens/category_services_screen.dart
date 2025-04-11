/*
Display services for a selected category
This screen shows all services available for a specific category
Users can view service details and select a service to book
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/search_category_service_api.dart';
import '../helpers/image_helper.dart';
import '../config/app_config.dart';

class CategoryServicesScreen extends StatefulWidget {
  // Category ID and name to display
  final int categoryId;
  final String categoryName;
  final String? categoryDescription;
  final String? categoryIconUrl;

  // Constructor
  const CategoryServicesScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    this.categoryIconUrl,
  }) : super(key: key);

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Category data
  Map<String, dynamic>? _categoryData;

  // Services list
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryServices();
  }

  // Load services for the selected category
  Future<void> _loadCategoryServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API to get services for this category
      final result = await SearchCategoryServiceApi.getServicesByCategory(widget.categoryId);

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
    final duration = service['duration'] ?? 0;
    final city = service['city'] ?? '';
    final postcode = service['postcode'] ?? '';

    // Format price as currency
    final formattedPrice = '£${price.toStringAsFixed(2)}';
    
    // Format duration
    final formattedDuration = '$duration mins';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to service detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
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
                      
                      // Duration
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
                          onPressed: _loadCategoryServices,
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
                      // Category header with icon
                      Row(
                        children: [
                          // Category icon
                          if (widget.categoryIconUrl != null)
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
                                  imageUrl: widget.categoryIconUrl!,
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
                                  widget.categoryName,
                                  style: AppStyles.headingStyle,
                                ),
                                if (widget.categoryDescription != null && widget.categoryDescription!.isNotEmpty)
                                  Text(
                                    widget.categoryDescription!,
                                    style: AppStyles.bodyStyle,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                                  'No services found for this category',
                                  style: AppStyles.subheadingStyle.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try selecting a different category or check back later',
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
