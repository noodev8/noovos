/*
User Bookings Screen
This screen shows bookings made by the logged-in user as a customer
Users can see their upcoming appointments, service details, and business information
This is for regular users to view their own bookings
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_user_bookings_api.dart';
import '../helpers/auth_helper.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  // State variables for managing the screen
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    // Load user bookings when screen initializes
    _loadUserBookings();
  }

  // Load user bookings from the API
  // This method calls the get_user_bookings endpoint
  Future<void> _loadUserBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API to get user bookings
      final result = await GetUserBookingsApi.getUserBookings();

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
            onPressed: _loadUserBookings,
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
              onPressed: _loadUserBookings,
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
                'You don\'t have any bookings at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppStyles.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserBookings,
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
      onRefresh: _loadUserBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(_bookings[index]);
        },
      ),
    );
  }

  // Format date and time display for better readability
  // Converts database format to user-friendly format
  String _formatDateTimeDisplay(String bookingDate, String startTime, String endTime) {
    try {
      // Parse the booking date (YYYY-MM-DD format from database)
      final date = DateTime.parse(bookingDate);

      // Format date as "Mon, 15 Jan 2025"
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final dayName = dayNames[date.weekday - 1];
      final monthName = monthNames[date.month - 1];
      final formattedDate = '$dayName, ${date.day} $monthName ${date.year}';

      // Format times (remove seconds if present)
      String formatTime(String time) {
        if (time.contains(':')) {
          final parts = time.split(':');
          if (parts.length >= 2) {
            return '${parts[0]}:${parts[1]}';
          }
        }
        return time;
      }

      final formattedStartTime = formatTime(startTime);
      final formattedEndTime = formatTime(endTime);

      return '$formattedDate\n$formattedStartTime - $formattedEndTime';

    } catch (e) {
      // Fallback to original format if parsing fails
      return '$bookingDate • $startTime - $endTime';
    }
  }

  // Build individual booking card
  // This shows all the important booking information for the user
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Extract booking data with safe defaults
    final serviceName = booking['service_name'] ?? 'Unknown Service';
    final businessName = booking['business_name'] ?? 'Unknown Business';
    final staffName = booking['staff_name'] ?? 'Unknown Staff';
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
                Expanded(
                  child: Text(
                    _formatDateTimeDisplay(bookingDate, startTime, endTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Staff information
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppStyles.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Staff: $staffName',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
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
