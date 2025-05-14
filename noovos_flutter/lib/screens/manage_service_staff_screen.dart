/*
Screen for managing staff assignments to services
Allows adding and removing staff members from a specific service
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/manage_staff_to_service_api.dart';
import '../api/get_service_staff_api.dart';
import '../api/get_business_staff_api.dart';

class ManageServiceStaffScreen extends StatefulWidget {
  // Required parameters
  final String serviceId;
  final String businessId;
  final String serviceName;

  // Constructor
  const ManageServiceStaffScreen({
    Key? key,
    required this.serviceId,
    required this.businessId,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<ManageServiceStaffScreen> createState() => _ManageServiceStaffScreenState();
}

class _ManageServiceStaffScreenState extends State<ManageServiceStaffScreen> {
  // State variables
  List<Map<String, dynamic>> _currentStaff = [];
  List<Map<String, dynamic>> _availableStaff = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Initialize the screen
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load all required data
  Future<void> _loadData() async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load current staff
      final currentStaffResponse = await GetServiceStaffApi.getServiceStaff(
        int.parse(widget.serviceId),
      );
      
      // Load available staff
      final availableStaffResponse = await GetBusinessStaffApi.getBusinessStaff(
        int.parse(widget.businessId),
      );

      // Update state with loaded data
      setState(() {
        if (currentStaffResponse['success']) {
          _currentStaff = List<Map<String, dynamic>>.from(currentStaffResponse['data']['staff'] ?? []);
        } else {
          _errorMessage = currentStaffResponse['message'] ?? 'Failed to load current staff';
        }
        if (availableStaffResponse['success']) {
          _availableStaff = List<Map<String, dynamic>>.from(availableStaffResponse['staff'] ?? []);
        } else {
          _errorMessage = availableStaffResponse['message'] ?? 'Failed to load available staff';
        }
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors
      setState(() {
        _errorMessage = 'Failed to load staff data: $e';
        _isLoading = false;
      });
    }
  }

  // Add staff to service
  Future<void> _addStaff(String staffId) async {
    try {
      // Call API to add staff
      final response = await ManageStaffToServiceApi.addStaffToService(
        serviceId: widget.serviceId,
        staffId: staffId,
        businessId: widget.businessId,
      );

      if (response['success']) {
        // Reload data to reflect changes
        await _loadData();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Staff added successfully'),
            backgroundColor: AppStyles.successColor,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to add staff'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add staff: $e'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  // Remove staff from service
  Future<void> _removeStaff(String staffId) async {
    try {
      // Call API to remove staff
      final response = await ManageStaffToServiceApi.removeStaffFromService(
        serviceId: widget.serviceId,
        staffId: staffId,
        businessId: widget.businessId,
      );

      if (response['success']) {
        // Reload data to reflect changes
        await _loadData();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Staff removed successfully'),
            backgroundColor: AppStyles.successColor,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to remove staff'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove staff: $e'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  // Get staff name from staff data
  String _getStaffName(Map<String, dynamic> staff) {
    final firstName = staff['first_name'] ?? '';
    final lastName = staff['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  // Build the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Staff - ${widget.serviceName}'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: AppStyles.errorColor)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Staff Section
                      Text('Current Staff', style: AppStyles.subheadingStyle),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _currentStaff.length,
                          itemBuilder: (context, index) {
                            final staff = _currentStaff[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(_getStaffName(staff)),
                                subtitle: Text(staff['role'] ?? 'No role specified'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: AppStyles.errorColor,
                                  onPressed: () => _removeStaff(staff['staff_id'].toString()),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Available Staff Section
                      Text('Available Staff', style: AppStyles.subheadingStyle),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _availableStaff.length,
                          itemBuilder: (context, index) {
                            final staff = _availableStaff[index];
                            // Check if staff is already assigned
                            final isAssigned = _currentStaff.any((s) => s['staff_id'] == staff['appuser_id']);
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(_getStaffName(staff)),
                                subtitle: Text(staff['role'] ?? 'No role specified'),
                                trailing: isAssigned
                                    ? const Icon(Icons.check_circle, color: AppStyles.successColor)
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        color: AppStyles.primaryColor,
                                        onPressed: () => _addStaff(staff['appuser_id'].toString()),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 