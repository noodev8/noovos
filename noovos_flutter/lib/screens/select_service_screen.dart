/*
Screen for selecting a service to manage its staff
This screen shows a list of services for a business
Allows selecting a service to manage its staff assignments
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_service_api.dart';
import 'manage_service_staff_screen.dart';

class SelectServiceScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Constructor
  const SelectServiceScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Services list
  List<Map<String, dynamic>> _services = [];

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
      // Get business ID
      final int businessId = widget.business['id'];

      // Call API to get services
      final result = await GetServiceApi.getBusinessServices(businessId);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _services = List<Map<String, dynamic>>.from(result['services'] ?? []);
            
            // If no services found, set an error message
            if (_services.isEmpty) {
              _errorMessage = 'No services found for this business.';
            }
          } else {
            _errorMessage = result['message'] ?? 'Failed to load services';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Navigate to manage service staff screen
  void _navigateToManageStaff(Map<String, dynamic> service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageServiceStaffScreen(
          serviceId: service['id'].toString(),
          businessId: widget.business['id'].toString(),
          serviceName: service['name'] ?? 'Unknown Service',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Service - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadServices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(service['name'] ?? 'Unknown Service'),
                        subtitle: Text(
                          service['description'] ?? 'No description available',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToManageStaff(service),
                      ),
                    );
                  },
                ),
    );
  }
} 