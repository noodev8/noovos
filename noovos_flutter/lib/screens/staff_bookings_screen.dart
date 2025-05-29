/*
Staff Bookings Screen
This screen shows bookings assigned to the logged-in staff member
This is the key screen that indicates a user is connected to a business as staff
Staff can see their upcoming appointments, customer details, and business information
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_staff_bookings_api.dart';
import '../helpers/auth_helper.dart';

class StaffBookingsScreen extends StatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  State<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends State<StaffBookingsScreen> {
  // State variables for managing the screen
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    // Load staff bookings when screen initializes
    _loadStaffBookings();
  }

  // Load staff bookings from the API
  // This method calls the get_staff_bookings endpoint
  Future<void> _loadStaffBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API to get staff bookings
      final result = await GetStaffBookingsApi.getStaffBookings();

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            // Successfully loaded bookings
            _bookings = List<Map<String, dynamic>>.from(result['bookings'] ?? []);
          } else {
            // Check if token has expired and handle accordingly
            if (AuthHelper.isTokenExpired(result)) {
              AuthHelper.handleTokenExpiration(context);
              return;
            }
            // Show error message
            _errorMessage = result['message'] ?? 'Failed to load bookings';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button to reload bookings
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaffBookings,
            tooltip: 'Refresh Bookings',
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBookingsView(),
    );
  }

  // Build error view when there's an error loading bookings
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppStyles.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStaffBookings,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Build the main bookings view
  Widget _buildBookingsView() {
    if (_bookings.isEmpty) {
      // Show empty state when no bookings found
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 64,
                color: AppStyles.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Bookings Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You don\'t have any bookings assigned to you at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppStyles.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStaffBookings,
                style: AppStyles.primaryButtonStyle,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Show list of bookings with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _loadStaffBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(_bookings[index]);
        },
      ),
    );
  }

  // Build individual booking card
  // This shows all the important booking information
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Extract booking data with safe defaults
    final serviceName = booking['service_name'] ?? 'Unknown Service';
    final businessName = booking['business_name'] ?? 'Unknown Business';
    final customerName = booking['customer_name'] ?? 'Unknown Customer';
    final customerEmail = booking['customer_email'] ?? '';
    final customerMobile = booking['customer_mobile'] ?? '';
    final bookingDate = booking['booking_date'] ?? '';
    final startTime = booking['start_time'] ?? '';
    final endTime = booking['end_time'] ?? '';
    final status = booking['status'] ?? 'unknown';
    final price = booking['service_price'] ?? 0;
    final currency = booking['service_currency'] ?? 'GBP';

    // Format price display
    final formattedPrice = currency == 'GBP' 
        ? '£${price.toStringAsFixed(2)}'
        : '$currency ${price.toStringAsFixed(2)}';

    // Get status color based on booking status
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppStyles.secondaryTextColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service and business info header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppStyles.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and time information
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppStyles.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '$bookingDate  •  $startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer information
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppStyles.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            // Customer mobile (if available)
            if (customerMobile.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppStyles.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    customerMobile,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Price information
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: AppStyles.primaryColor),
                const SizedBox(width: 8),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryColor,
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
