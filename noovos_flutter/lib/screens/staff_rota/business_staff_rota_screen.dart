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
import '../../api/get_staff_rota_api.dart';
import '../../widgets/week_picker_widget.dart';
import 'add_staff_rota_screen.dart';

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
  Map<String, dynamic>? _selectedWeekData;

  // Rota data
  bool _loadingRotaData = false;
  Map<int, Map<String, dynamic>> _staffHours = {}; // Map of staff ID to hours data

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  // Handle week selection from the WeekPickerWidget
  void _onWeekSelected(int index, Map<String, dynamic> weekData) {
    if (index != _selectedWeekIndex || _selectedWeekData == null) {
      setState(() {
        _selectedWeekIndex = index;
        _selectedWeekData = weekData;
      });

      // Load rota data for the new week
      _loadRotaData();
    }
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

            // Load rota data after staff is loaded
            _loadRotaData();
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

  // Format time string to DateTime
  DateTime _parseTimeString(String timeStr) {
    // The API returns time in format "HH12:MI AM" like "09:00 AM"
    try {
      // Parse the time string
      final DateFormat format = DateFormat('hh:mm a');
      return format.parse(timeStr);
    } catch (e) {
      // Fallback for other formats (like "09:00")
      try {
        final List<String> parts = timeStr.split(':');
        final int hours = int.parse(parts[0]);
        final int minutes = int.parse(parts[1].split(' ')[0]); // Remove AM/PM if present

        // Use a base date (doesn't matter which one)
        return DateTime(2023, 1, 1, hours, minutes);
      } catch (e) {
        // Error parsing time
        return DateTime(2023, 1, 1); // Return midnight as fallback
      }
    }
  }

  // Calculate hours between two time strings
  double _calculateHours(String startTime, String endTime) {
    try {
      final DateTime start = _parseTimeString(startTime);
      final DateTime end = _parseTimeString(endTime);

      // Calculate difference in minutes
      final int differenceMinutes = end.difference(start).inMinutes;

      // Convert to hours (with decimal)
      return differenceMinutes / 60.0;
    } catch (e) {
      // Error calculating hours
      return 0.0;
    }
  }

  // Load rota data for all staff for the selected week
  Future<void> _loadRotaData() async {
    // Skip if no staff or no week selected
    if (_staffList.isEmpty || _selectedWeekData == null) {
      return;
    }

    setState(() {
      _loadingRotaData = true;
    });

    try {
      // Get business ID
      final int businessId = widget.business['id'];

      // Get selected week dates
      final DateTime startDate = _selectedWeekData!['startDate'];
      final DateTime endDate = _selectedWeekData!['endDate'];

      // Format dates for API (YYYY-MM-DD)
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Clear previous data
      final Map<int, Map<String, dynamic>> newStaffHours = {};

      // Initialize with zero hours for all staff
      for (final staff in _staffList) {
        final int staffId = staff['id'];
        newStaffHours[staffId] = {
          'totalHours': 0.0,
          'entries': [],
        };
      }

      // For each staff member, get their rota entries
      for (final staff in _staffList) {
        final int staffId = staff['id'];

        // Call API to get rota entries
        final result = await GetStaffRotaApi.getStaffRota(
          businessId: businessId,
          staffId: staffId,
          startDate: startDateStr,
          endDate: endDateStr,
        );

        if (result['success']) {
          final List<Map<String, dynamic>> rotaEntries = List<Map<String, dynamic>>.from(result['rota']);

          // Process rota entries
          double totalHours = 0.0;

          // Calculate total hours
          for (final entry in rotaEntries) {
            final String startTime = entry['start_time'];
            final String endTime = entry['end_time'];

            final double hours = _calculateHours(startTime, endTime);

            totalHours += hours;
          }

          // Store data
          newStaffHours[staffId] = {
            'totalHours': totalHours,
            'entries': rotaEntries,
          };
        }
      }

      if (mounted) {
        setState(() {
          _staffHours = newStaffHours;
          _loadingRotaData = false;
        });

        // Show debug message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded hours data for ${newStaffHours.length} staff members'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRotaData = false;
        });

        // Show error in snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load rota data: $e'),
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
              'Each week runs from Sunday to Saturday',
              style: TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),

            // Week picker
            WeekPickerWidget(
              numberOfWeeks: 12,
              initialWeekIndex: _selectedWeekIndex,
              onWeekSelected: _onWeekSelected,
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
        // Header with loading indicator
        Row(
          children: [
            const Text(
              'Staff Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (_loadingRotaData)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Selected week info
        if (_selectedWeekData != null)
          Text(
            'Week: ${_formatDisplayDate(_selectedWeekData!['startDate'])} - ${_formatDisplayDate(_selectedWeekData!['endDate'])}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
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
    final int staffId = staff['id'];
    final String name = staff['name'];

    // Get hours data for this staff member
    final bool hasHoursData = _staffHours.containsKey(staffId);

    // Get total hours (safely handle potential type issues)
    double totalHours = 0.0;
    if (hasHoursData) {
      final dynamic hoursValue = _staffHours[staffId]!['totalHours'];
      if (hoursValue is double) {
        totalHours = hoursValue;
      } else if (hoursValue is int) {
        totalHours = hoursValue.toDouble();
      } else if (hoursValue is String) {
        totalHours = double.tryParse(hoursValue) ?? 0.0;
      }
    }

    // Check if there are any entries
    final bool hasEntries = hasHoursData &&
                           _staffHours[staffId]!.containsKey('entries') &&
                           (_staffHours[staffId]!['entries'] as List).isNotEmpty;

    // Format total hours (show 1 decimal place)
    final String formattedHours = totalHours.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Ensure we have week data (should always be populated after initial load)
          if (_selectedWeekData == null) {
            // Generate week data from the current week if not set yet
            final DateTime now = DateTime.now();
            final DateTime currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
            final DateTime currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
            
            _selectedWeekData = {
              'index': 0,
              'startDate': currentWeekStart,
              'endDate': currentWeekEnd,
              'displayText': '${_formatDisplayDate(currentWeekStart)} - ${_formatDisplayDate(currentWeekEnd)}',
            };
          }

          // Navigate to add staff rota screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStaffRotaScreen(
                business: widget.business,
                staff: {
                  'appuser_id': staffId,
                  'first_name': name.split(' ').first,
                  'last_name': name.split(' ').length > 1 ? name.split(' ').last : '',
                },
                weekData: _selectedWeekData!,
              ),
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
                    if (!_loadingRotaData) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hours: $formattedHours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasEntries ? AppStyles.primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Loading indicator or arrow icon
              if (_loadingRotaData)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
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
