/*
Service Management Screen
This screen allows business owners and staff to manage services for their business
Features:
- View all services for the business
- Add new services
- Edit existing services
- Delete services (soft delete)
- Filter active/inactive services
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_service_api.dart';
import '../api/delete_service_api.dart';
import 'add_edit_service_screen.dart';

class ServiceManagementScreen extends StatefulWidget {
  final Map<String, dynamic> business;

  const ServiceManagementScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactiveServices = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // Load services for the business
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to get business services
      final result = await GetServiceApi.getBusinessServices(widget.business['id']);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _services = result['services'] ?? [];
          } else {
            _errorMessage = result['message'] ?? 'Failed to load services.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  // Filter services based on active status
  List<dynamic> get _filteredServices {
    if (_showInactiveServices) {
      return _services;
    } else {
      return _services.where((service) => service['active'] == true).toList();
    }
  }

  // Navigate to add service screen
  void _addService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(
          business: widget.business,
          isEditing: false,
        ),
      ),
    ).then((_) {
      // Refresh services list when returning from add screen
      _loadServices();
    });
  }

  // Navigate to edit service screen
  void _editService(Map<String, dynamic> service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(
          business: widget.business,
          isEditing: true,
          service: service,
        ),
      ),
    ).then((_) {
      // Refresh services list when returning from edit screen
      _loadServices();
    });
  }

  // Delete service with confirmation
  Future<void> _deleteService(Map<String, dynamic> service) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: Text(
            'Are you sure you want to delete "${service['service_name']}"?\n\n'
            'This will make the service unavailable for new bookings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppStyles.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        // Call delete API
        final result = await DeleteServiceApi.deleteService(service['id']);

        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (result['success']) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Service deleted successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          }

          // Refresh services list
          _loadServices();
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to delete service'),
                backgroundColor: AppStyles.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Services - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Toggle inactive services visibility
          IconButton(
            icon: Icon(_showInactiveServices ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showInactiveServices = !_showInactiveServices;
              });
            },
            tooltip: _showInactiveServices ? 'Hide Inactive Services' : 'Show Inactive Services',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppStyles.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: AppStyles.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServices,
                        style: AppStyles.primaryButtonStyle,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildServicesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        backgroundColor: AppStyles.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServicesList() {
    final filteredServices = _filteredServices;

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: AppStyles.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              _showInactiveServices
                  ? 'No services found'
                  : 'No active services found',
              style: AppStyles.subheadingStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first service',
              style: AppStyles.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive = service['active'] == true;
    final price = service['price'] is String
        ? double.tryParse(service['price']) ?? 0.0
        : (service['price'] as num).toDouble();
    final duration = service['duration'] is String
        ? int.tryParse(service['duration']) ?? 0
        : service['duration'] as int;
    final bufferTime = service['buffer_time'] is String
        ? int.tryParse(service['buffer_time']) ?? 0
        : (service['buffer_time'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    service['service_name'] ?? 'Unnamed Service',
                    style: AppStyles.subheadingStyle.copyWith(
                      color: isActive ? AppStyles.textColor : AppStyles.secondaryTextColor,
                    ),
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppStyles.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: AppStyles.captionStyle.copyWith(
                        color: AppStyles.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            if (service['description'] != null && service['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  service['description'],
                  style: AppStyles.bodyStyle.copyWith(
                    color: isActive ? AppStyles.textColor : AppStyles.secondaryTextColor,
                  ),
                ),
              ),

            // Service details
            Row(
              children: [
                // Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: AppStyles.captionStyle,
                      ),
                      Text(
                        '£${price.toStringAsFixed(2)}',
                        style: AppStyles.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppStyles.textColor : AppStyles.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: AppStyles.captionStyle,
                      ),
                      Text(
                        '${duration}min',
                        style: AppStyles.bodyStyle.copyWith(
                          color: isActive ? AppStyles.textColor : AppStyles.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Buffer time
                if (bufferTime > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buffer',
                          style: AppStyles.captionStyle,
                        ),
                        Text(
                          '${bufferTime}min',
                          style: AppStyles.bodyStyle.copyWith(
                            color: isActive ? AppStyles.textColor : AppStyles.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  onPressed: () => _editService(service),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.primaryColor,
                  ),
                ),

                const SizedBox(width: 8),

                // Delete button (only show for active services)
                if (isActive)
                  TextButton.icon(
                    onPressed: () => _deleteService(service),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppStyles.errorColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
