/*
Business Staff Rota Management Screen
This screen allows business owners to manage staff working hours (rota)
Features:
- View staff rota entries
- Add new rota entries (single or bulk)
- Edit existing rota entries
- Delete rota entries
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';
import '../api/get_business_staff_api.dart';

class BusinessStaffRotaScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Constructor
  const BusinessStaffRotaScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<BusinessStaffRotaScreen> createState() => _BusinessStaffRotaScreenState();
}

class _BusinessStaffRotaScreenState extends State<BusinessStaffRotaScreen> {
  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // Staff list
  List<Map<String, dynamic>> _staffList = [];

  // Selected staff member
  Map<String, dynamic>? _selectedStaff;

  // Selected date
  DateTime _selectedDate = DateTime.now();

  // Time controllers
  final TextEditingController _startTimeController = TextEditingController(text: '09:00');
  final TextEditingController _endTimeController = TextEditingController(text: '17:00');

  // Rota entries (placeholder for now)
  final List<Map<String, dynamic>> _rotaEntries = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // Load staff members from API
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
            // Process staff data
            final List<Map<String, dynamic>> staffData = List<Map<String, dynamic>>.from(result['staff']);

            // Filter to only include active staff members
            _staffList = staffData
                .where((staff) => staff['status'] == 'active')
                .map((staff) {
                  // Format staff data for dropdown
                  final String firstName = staff['first_name'] ?? '';
                  final String lastName = staff['last_name'] ?? '';
                  final String fullName = '$firstName $lastName'.trim();

                  return {
                    'id': staff['appuser_id'],
                    'name': fullName,
                    'email': staff['email'] ?? '',
                    'role': staff['role'] ?? '',
                  };
                })
                .toList();
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

  // Format date (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    // Parse current time from controller
    final List<String> timeParts = controller.text.split(':');
    final TimeOfDay initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 9,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Rota - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : _buildRotaManagementUI(),
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
              color: AppStyles.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyles.errorColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build rota management UI
  Widget _buildRotaManagementUI() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Staff selection section
              _buildStaffSelectionSection(),

              const SizedBox(height: 24),

              // Add rota entry section
              _buildAddRotaEntrySection(),

              const SizedBox(height: 24),

              // Rota entries section
              _buildRotaEntriesSection(),
            ],
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.white.withAlpha(178), // 0.7 opacity = 178/255
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // Build staff selection section
  Widget _buildStaffSelectionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Staff Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(
                labelText: 'Staff Member',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a staff member'),
              value: _selectedStaff,
              items: _staffList.map((staff) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: staff,
                  child: Text(staff['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStaff = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build add rota entry section
  Widget _buildAddRotaEntrySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Working Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time pickers
            Row(
              children: [
                // Start time
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, _startTimeController),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _startTimeController.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // End time
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, _endTimeController),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _endTimeController.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // This will be implemented later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This feature is coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Working Hours'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build rota entries section
  Widget _buildRotaEntriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scheduled Working Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Placeholder for rota entries
        if (_rotaEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No working hours scheduled',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              ),
            ),
          )
        else
          ..._rotaEntries.map(_buildRotaEntryCard),
      ],
    );
  }

  // Build rota entry card
  Widget _buildRotaEntryCard(Map<String, dynamic> entry) {
    // This is a placeholder - will be implemented with real data later
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Staff Name'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: 2023-05-01'),
            Text('Time: 09:00 - 17:00'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppStyles.primaryColor),
              onPressed: () {
                // Edit functionality will be implemented later
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete functionality will be implemented later
              },
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
