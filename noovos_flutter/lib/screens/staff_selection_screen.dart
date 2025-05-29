/*
Display staff selection for a service
This screen allows users to select a staff member for a service or choose "Any Staff"
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/image_helper.dart';
import '../helpers/cloudinary_helper.dart';
import '../helpers/cart_helper.dart';
import '../api/get_service_staff_api.dart';

class StaffSelectionScreen extends StatefulWidget {
  // Service details to add to cart
  final Map<String, dynamic> serviceDetails;

  // Constructor
  const StaffSelectionScreen({
    Key? key,
    required this.serviceDetails,
  }) : super(key: key);

  @override
  State<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends State<StaffSelectionScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Staff list
  List<Map<String, dynamic>> _staffList = [];

  // Selected staff ID (null means any staff - default)
  int? _selectedStaffId;

  // Selected staff name
  String? _selectedStaffName;

  @override
  void initState() {
    super.initState();

    // Load staff list
    _loadStaffList();
  }

  // Load staff list from API
  Future<void> _loadStaffList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get service ID from service details
      final int serviceId = widget.serviceDetails['service_id'] ?? 0;

      // Call the API to get staff list
      final result = await GetServiceStaffApi.getServiceStaff(serviceId);

      if (!mounted) return;

      // Check if the request was successful
      if (result['success']) {
        final data = result['data'];
        final staffList = data['staff'] as List<dynamic>;

        setState(() {
          _staffList = List<Map<String, dynamic>>.from(staffList);
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load staff list';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Handle error
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // Add service to cart with selected staff
  void _addToCartWithStaff() {
    // Create cart item with selected staff
    final cartItem = CartItem(
      serviceId: widget.serviceDetails['service_id'] ?? 0,
      serviceName: widget.serviceDetails['service_name'] ?? 'Unknown Service',
      businessId: widget.serviceDetails['business_id'] ?? 0,
      businessName: widget.serviceDetails['business_name'] ?? 'Unknown Business',
      price: widget.serviceDetails['price'] != null
          ? (widget.serviceDetails['price'] is String
              ? double.tryParse(widget.serviceDetails['price']) ?? 0.0
              : widget.serviceDetails['price'] is num
                  ? widget.serviceDetails['price'].toDouble()
                  : 0.0)
          : 0.0,
      serviceImage: widget.serviceDetails['service_image'],
      duration: widget.serviceDetails['duration'] ?? 0,
      staffId: _selectedStaffId,
      staffName: _selectedStaffName,
    );

    // Add to cart
    CartHelper.addToCart(cartItem).then((success) {
      if (success) {
        // Show success message and return to previous screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.serviceDetails['service_name']} added to cart'),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to cart screen and replace the current screen
          Navigator.of(context).pushReplacementNamed('/cart');
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add service to cart'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Staff'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _errorMessage != null
            ? _buildErrorView()
            : Stack(
                children: [
                  // Always show the staff list UI (even when loading)
                  _buildStaffList(),

                  // Show loading overlay when loading
                  if (_isLoading)
                    Container(
                      color: Colors.white.withAlpha(178), // 0.7 opacity = 178/255
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: _isLoading || _errorMessage != null
            ? null
            : _buildBottomBar(),
      ),
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
            Text(
              'Error loading staff list',
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
              onPressed: _loadStaffList,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Build staff list
  Widget _buildStaffList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service info
            Text(
              widget.serviceDetails['service_name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.serviceDetails['business_name'],
              style: const TextStyle(
                fontSize: 16,
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Staff selection heading
            const Text(
              'Choose a staff member or select "Any Staff"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Any staff option
            _buildStaffOption(
              null,
              'Any Staff',
              'Let the salon assign any available staff member',
              null,
            ),
            const SizedBox(height: 16),

            // Staff list
            if (_staffList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No staff members available for this service',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              )
            else
              ..._staffList.map((staff) {
                final int staffId = staff['staff_id'] ?? 0;
                final String firstName = staff['first_name'] ?? '';
                final String lastName = staff['last_name'] ?? '';
                final String fullName = '$firstName $lastName'.trim();
                final String? imageName = staff['image_name'];
                final String? bio = staff['bio'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStaffOption(
                    staffId,
                    fullName,
                    bio ?? '',  // Changed from bio ?? role to just bio ?? ''
                    imageName,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Build staff option card
  Widget _buildStaffOption(int? staffId, String name, String? description, String? imageName) {
    final bool isSelected = _selectedStaffId == staffId;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppStyles.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStaffId = staffId;
            _selectedStaffName = staffId != null ? name : null;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Staff image or placeholder
              if (staffId != null)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: imageName != null
                        ? ImageHelper.getCachedNetworkImage(
                            imageUrl: CloudinaryHelper.getCloudinaryUrl(imageName),
                            fit: BoxFit.cover,
                            errorWidget: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 30,
                    color: AppStyles.primaryColor,
                  ),
                ),
              const SizedBox(width: 16),

              // Staff details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppStyles.secondaryTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              Radio<int?>(
                value: staffId,
                groupValue: _selectedStaffId,
                onChanged: (value) {
                  setState(() {
                    _selectedStaffId = value;
                    _selectedStaffName = value != null ? name : null;
                  });
                },
                activeColor: AppStyles.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build bottom bar with action buttons
  Widget _buildBottomBar() {
    return Container(
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
          // Cancel button
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: AppStyles.secondaryButtonStyle,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),

          // Add to cart button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _addToCartWithStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}



