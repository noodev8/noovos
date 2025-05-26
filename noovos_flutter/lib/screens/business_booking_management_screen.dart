/*
Business Booking Management Screen
This screen allows business owners to view and manage all bookings for their business
Features:
- View all bookings for the business
- Filter bookings by staff member
- View customer contact details
- Delete bookings
- See booking details (service, date, time, status)
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';
import '../api/get_business_bookings_api.dart';
import '../api/delete_booking_api.dart';
import '../api/get_business_staff_api.dart';

class BusinessBookingManagementScreen extends StatefulWidget {
  final Map<String, dynamic> business;

  const BusinessBookingManagementScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<BusinessBookingManagementScreen> createState() => _BusinessBookingManagementScreenState();
}

class _BusinessBookingManagementScreenState extends State<BusinessBookingManagementScreen> {
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _bookings = [];
  List<dynamic> _staff = [];
  int? _selectedStaffId;
  String _selectedStaffName = 'All Staff';

  // Date filtering
  String _selectedDateFilter = 'All Time';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Load initial data (staff and bookings)
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load staff first
      await _loadStaff();

      // Then load bookings
      await _loadBookings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Load staff members for the business
  Future<void> _loadStaff() async {
    try {
      final result = await GetBusinessStaffApi.getBusinessStaff(
        widget.business['id'],
      );

      if (result['success']) {
        setState(() {
          _staff = result['staff'] ?? [];
        });
      }
    } catch (e) {
      // Handle error silently or show user-friendly message if needed
    }
  }

  // Load bookings for the business
  Future<void> _loadBookings() async {
    try {
      final result = await GetBusinessBookingsApi.getBusinessBookings(
        businessId: widget.business['id'],
        staffId: _selectedStaffId,
      );

      if (result['success']) {
        setState(() {
          _bookings = result['bookings'] ?? [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading bookings: $e';
        _isLoading = false;
      });
    }
  }

  // Filter bookings by staff member
  Future<void> _filterByStaff(int? staffId, String staffName) async {
    setState(() {
      _selectedStaffId = staffId;
      _selectedStaffName = staffName;
      _isLoading = true;
    });

    await _loadBookings();
  }

  // Filter bookings by date
  void _filterByDate(String filter) {
    setState(() {
      _selectedDateFilter = filter;
      _isLoading = true;
    });

    // Calculate date range based on filter
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        _customStartDate = DateTime(now.year, now.month, now.day);
        _customEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _customStartDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _customEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Month':
        _customStartDate = DateTime(now.year, now.month, 1);
        _customEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Next 7 Days':
        _customStartDate = DateTime(now.year, now.month, now.day);
        _customEndDate = DateTime(now.year, now.month, now.day + 7, 23, 59, 59);
        break;
      case 'Next 30 Days':
        _customStartDate = DateTime(now.year, now.month, now.day);
        _customEndDate = DateTime(now.year, now.month, now.day + 30, 23, 59, 59);
        break;
      default: // 'All Time'
        _customStartDate = null;
        _customEndDate = null;
        break;
    }

    _loadBookings();
  }

  // Filter bookings by date range
  List<dynamic> _getFilteredBookings() {
    if (_customStartDate == null || _customEndDate == null) {
      return _bookings;
    }

    return _bookings.where((booking) {
      try {
        final bookingDate = DateTime.parse(booking['booking_date']);
        return bookingDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
               bookingDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
      } catch (e) {
        return true; // Include booking if date parsing fails
      }
    }).toList();
  }

  // Delete a booking
  Future<void> _deleteBooking(Map<String, dynamic> booking) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text(
          'Are you sure you want to delete this booking?\n\n'
          'Customer: ${booking['customer_name']}\n'
          'Service: ${booking['service_name']}\n'
          'Date: ${_formatDate(booking['booking_date'])}\n'
          'Time: ${_formatTime(booking['start_time'])}',
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
      ),
    );

    if (confirmed == true) {
      try {
        final result = await DeleteBookingApi.deleteBooking(
          bookingId: booking['booking_id'],
        );

        if (result['success']) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Booking deleted successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          }

          // Reload bookings
          await _loadBookings();
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to delete booking'),
                backgroundColor: AppStyles.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting booking: $e'),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        }
      }
    }
  }

  // Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Format time for display
  String _formatTime(String timeString) {
    try {
      final time = DateFormat('HH:mm:ss').parse(timeString);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return timeString;
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppStyles.successColor;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return AppStyles.errorColor;
      default:
        return AppStyles.secondaryTextColor;
    }
  }

  // Build filters section
  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: AppStyles.subheadingStyle),
            const SizedBox(height: 16),

            // Staff filter
            Text('Staff Member', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedStaffId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Staff'),
                ),
                ..._staff.map<DropdownMenuItem<int?>>((staff) {
                  return DropdownMenuItem<int?>(
                    value: staff['appuser_id'],
                    child: Text('${staff['first_name']} ${staff['last_name']}'),
                  );
                }),
              ],
              onChanged: (value) {
                final staffName = value == null
                    ? 'All Staff'
                    : '${_staff.firstWhere((s) => s['appuser_id'] == value, orElse: () => {})['first_name']} ${_staff.firstWhere((s) => s['appuser_id'] == value, orElse: () => {})['last_name']}';
                _filterByStaff(value, staffName);
              },
            ),

            const SizedBox(height: 16),

            // Date filter
            Text('Date Range', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDateFilter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'All Time',
                  child: Text('All Time'),
                ),
                DropdownMenuItem<String>(
                  value: 'Today',
                  child: Text('Today'),
                ),
                DropdownMenuItem<String>(
                  value: 'This Week',
                  child: Text('This Week'),
                ),
                DropdownMenuItem<String>(
                  value: 'This Month',
                  child: Text('This Month'),
                ),
                DropdownMenuItem<String>(
                  value: 'Next 7 Days',
                  child: Text('Next 7 Days'),
                ),
                DropdownMenuItem<String>(
                  value: 'Next 30 Days',
                  child: Text('Next 30 Days'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _filterByDate(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
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
            onPressed: _loadInitialData,
            style: AppStyles.primaryButtonStyle,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Build bookings view
  Widget _buildBookingsView() {
    final filteredBookings = _getFilteredBookings();

    return Column(
      children: [
        // Filters
        _buildFilters(),

        // Bookings count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${filteredBookings.length} booking${filteredBookings.length != 1 ? 's' : ''}',
                style: AppStyles.subheadingStyle,
              ),
              if (_selectedStaffId != null) ...[
                const Text(' for '),
                Text(
                  _selectedStaffName,
                  style: AppStyles.subheadingStyle.copyWith(
                    color: AppStyles.primaryColor,
                  ),
                ),
              ],
              if (_selectedDateFilter != 'All Time') ...[
                const Text(' in '),
                Text(
                  _selectedDateFilter.toLowerCase(),
                  style: AppStyles.subheadingStyle.copyWith(
                    color: AppStyles.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bookings list
        Expanded(
          child: filteredBookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
        ),
      ],
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    String emptyMessage = 'No bookings found';

    if (_selectedStaffId != null && _selectedDateFilter != 'All Time') {
      emptyMessage = 'No bookings found for $_selectedStaffName in ${_selectedDateFilter.toLowerCase()}';
    } else if (_selectedStaffId != null) {
      emptyMessage = 'No bookings found for $_selectedStaffName';
    } else if (_selectedDateFilter != 'All Time') {
      emptyMessage = 'No bookings found in ${_selectedDateFilter.toLowerCase()}';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppStyles.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: AppStyles.bodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStaffId != null || _selectedDateFilter != 'All Time'
                ? 'Try adjusting your filters to see more bookings'
                : 'Bookings will appear here when customers make appointments',
            style: AppStyles.bodyStyle.copyWith(
              color: AppStyles.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),

          // Clear filters button if filters are applied
          if (_selectedStaffId != null || _selectedDateFilter != 'All Time') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedStaffId = null;
                  _selectedStaffName = 'All Staff';
                  _selectedDateFilter = 'All Time';
                  _customStartDate = null;
                  _customEndDate = null;
                });
                _loadBookings();
              },
              style: AppStyles.primaryButtonStyle,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // Build booking card
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with service and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking['service_name'] ?? 'Unknown Service',
                    style: AppStyles.subheadingStyle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status'] ?? 'unknown'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (booking['status'] ?? 'unknown').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date and time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppStyles.secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(booking['booking_date'] ?? ''),
                      style: AppStyles.bodyStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppStyles.secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTime(booking['start_time'] ?? '')} - ${_formatTime(booking['end_time'] ?? '')}',
                      style: AppStyles.bodyStyle,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Staff member
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppStyles.secondaryTextColor),
                const SizedBox(width: 8),
                Text(
                  'Staff: ${booking['staff_name'] ?? 'Unknown'}',
                  style: AppStyles.bodyStyle,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Price
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: AppStyles.secondaryTextColor),
                const SizedBox(width: 8),
                Text(
                  '${booking['service_currency'] ?? 'GBP'} ${booking['service_price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: AppStyles.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Customer details section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Details',
                    style: AppStyles.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Customer name
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppStyles.secondaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                        booking['customer_name'] ?? 'Unknown Customer',
                        style: AppStyles.bodyStyle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Customer email
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppStyles.secondaryTextColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking['customer_email'] ?? 'No email',
                          style: AppStyles.bodyStyle,
                        ),
                      ),
                    ],
                  ),

                  // Customer mobile (if available)
                  if (booking['customer_mobile'] != null && booking['customer_mobile'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppStyles.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text(
                          booking['customer_mobile'],
                          style: AppStyles.bodyStyle,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteBooking(booking),
                  icon: const Icon(Icons.delete_outline, color: AppStyles.errorColor),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppStyles.errorColor),
                  ),
                ),
              ],
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
        title: Text('Bookings - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildBookingsView(),
    );
  }
}
