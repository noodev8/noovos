/*
Business Staff Management Screen
This screen allows business owners to manage staff members for their business
Features:
- View current staff members
- Send join requests to new staff members
- Accept/reject pending requests
- Remove existing staff members
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_business_staff_api.dart';
import '../api/request_staff_join_api.dart';

import '../api/remove_staff_api.dart';

class BusinessStaffManagementScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Constructor
  const BusinessStaffManagementScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<BusinessStaffManagementScreen> createState() => _BusinessStaffManagementScreenState();
}

class _BusinessStaffManagementScreenState extends State<BusinessStaffManagementScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Staff list
  List<Map<String, dynamic>> _staffList = [];

  // Email controller for adding new staff
  final TextEditingController _emailController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Load staff members
  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get business ID
      final int businessId = widget.business['id'];

      // Call API to get staff members
      final result = await GetBusinessStaffApi.getBusinessStaff(businessId);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _staffList = List<Map<String, dynamic>>.from(result['staff']);
          } else {
            _errorMessage = result['message'] ?? 'Failed to load staff members';
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

  // Request staff join
  Future<void> _requestStaffJoin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get business ID and email
      final int businessId = widget.business['id'];
      final String email = _emailController.text.trim();

      // Call API to request staff join
      final result = await RequestStaffJoinApi.requestStaffJoin(businessId, email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success or error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        // If successful, clear the email field and reload staff list
        if (result['success']) {
          _emailController.clear();
          _loadStaff();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove staff member
  Future<void> _removeStaff(int appuserId, String staffName) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff Member'),
        content: Text('Are you sure you want to remove $staffName from your staff?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get business ID
      final int businessId = widget.business['id'];

      // Call API to remove staff member
      final result = await RemoveStaffApi.removeStaff(businessId, appuserId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success or error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        // If successful, reload staff list
        if (result['success']) {
          _loadStaff();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Management - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : Stack(
              children: [
                // Always show the staff management UI (even when loading)
                _buildStaffManagementUI(),

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
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
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
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Build staff management UI
  Widget _buildStaffManagementUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add new staff section
          _buildAddStaffSection(),

          const SizedBox(height: 24),

          // Staff list section
          _buildStaffListSection(),
        ],
      ),
    );
  }

  // Build add staff section
  Widget _buildAddStaffSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Staff Member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter staff member\'s email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestStaffJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Send Invitation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build staff list section
  Widget _buildStaffListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff Members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Active staff members
        ..._buildStaffList('active'),

        const SizedBox(height: 16),

        // Pending staff requests
        const Text(
          'Pending Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Pending staff members
        ..._buildStaffList('pending'),
      ],
    );
  }

  // Build staff list for a specific status
  List<Widget> _buildStaffList(String status) {
    // Filter staff by status
    final filteredStaff = _staffList.where((staff) => staff['status'] == status).toList();

    if (filteredStaff.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            status == 'active'
                ? 'No staff members found'
                : 'No pending requests',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    return filteredStaff.map((staff) {
      // Get staff details
      final int appuserId = staff['appuser_id'];
      final String firstName = staff['first_name'] ?? '';
      final String lastName = staff['last_name'] ?? '';
      final String fullName = '$firstName $lastName'.trim();
      final String email = staff['email'] ?? '';
      final String role = staff['role'] ?? '';

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              Text(
                'Role: $role',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          trailing: status == 'active'
              ? (role.toLowerCase() == 'business_owner'
                  ? null  // No delete button for business owners
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeStaff(appuserId, fullName),
                      tooltip: 'Remove staff member',
                    )
                )
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeStaff(appuserId, fullName),
                  tooltip: 'Cancel request',
                ),
        ),
      );
    }).toList();
  }
}
