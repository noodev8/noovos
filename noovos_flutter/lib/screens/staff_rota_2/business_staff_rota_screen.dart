/*
Business Staff Rota Management Screen (Version 2)
This screen allows business owners to manage staff working hours (rota)
Features:
- Select week range for viewing/editing rota
- View staff list for the business
- Tap on staff to manage their hours (to be implemented)
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../styles/app_styles.dart';
import '../../api/get_business_staff_api.dart';

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
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Staff list
  List<Map<String, dynamic>> _staffList = [];

  // Week selection
  int _selectedWeekIndex = 0;
  List<Map<String, dynamic>> _weekOptions = [];

  @override
  void initState() {
    super.initState();
    _generateWeekOptions();
    _loadStaff();
  }

  // Generate week options (Sunday to Saturday)
  void _generateWeekOptions() {
    // Get the current date
    final DateTime now = DateTime.now();

    // Find the most recent Sunday (start of the week)
    final DateTime currentWeekStart = now.subtract(Duration(days: now.weekday % 7));

    // Generate 12 weeks (current week + 11 weeks forward)
    _weekOptions = List.generate(12, (index) {
      // Calculate start date (Sunday) for this week
      final DateTime startDate = currentWeekStart.add(Duration(days: 7 * index));

      // Calculate end date (Saturday) for this week
      final DateTime endDate = startDate.add(const Duration(days: 6));

      // Format dates for display
      final String displayText = '${_formatDisplayDate(startDate)} - ${_formatDisplayDate(endDate)}';

      return {
        'index': index,
        'startDate': startDate,
        'endDate': endDate,
        'displayText': displayText,
      };
    });
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
                  // Format staff data
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



  // Format display date (e.g., "1 May 2023")
  String _formatDisplayDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Change selected week
  void _onWeekChanged(int? newIndex) {
    if (newIndex != null && newIndex != _selectedWeekIndex) {
      setState(() {
        _selectedWeekIndex = newIndex;
      });
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
          : Stack(
              children: [
                _buildRotaManagementUI(),
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

  // Build rota management UI
  Widget _buildRotaManagementUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range selection
          _buildDateRangeSection(),

          const SizedBox(height: 24),

          // Staff list
          _buildStaffListSection(),
        ],
      ),
    );
  }

  // Build week selection section
  Widget _buildDateRangeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each week runs from Sunday to Saturday',
              style: TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),

            // Week dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Week',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              value: _selectedWeekIndex,
              items: _weekOptions.map((week) {
                return DropdownMenuItem<int>(
                  value: week['index'],
                  child: Text(week['displayText']),
                );
              }).toList(),
              onChanged: _onWeekChanged,
              isExpanded: true,
            ),

            const SizedBox(height: 8),

            // Current selection info
            if (_weekOptions.isNotEmpty)
              Text(
                'Selected: ${_weekOptions[_selectedWeekIndex]['displayText']}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppStyles.secondaryTextColor,
                ),
              ),
          ],
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
        const Text(
          'Tap on a staff member to manage their working hours',
          style: TextStyle(
            color: AppStyles.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 16),

        // Staff list
        if (_staffList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No staff members found',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppStyles.secondaryTextColor,
              ),
            ),
          )
        else
          ..._staffList.map(_buildStaffCard),
      ],
    );
  }

  // Build staff card
  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final String name = staff['name'];
    final String email = staff['email'];
    final String role = staff['role'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Show message for now (will be implemented later)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Manage hours for $name - Coming soon!'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Staff icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppStyles.primaryColor,
                  size: 30,
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
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppStyles.secondaryTextColor,
                      ),
                    ),
                    Text(
                      'Role: $role',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppStyles.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                color: AppStyles.secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
