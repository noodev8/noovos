/*
Comprehensive Bookings Screen
This screen shows different booking views based on user type:
- Normal users: See their customer bookings
- Staff users: See both their customer bookings AND appointments they're assigned to (separately)
- Business owners: See customer bookings, assigned appointments, AND business management screens
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/get_user_bookings_api.dart';
import '../api/get_staff_bookings_api.dart';
import '../helpers/auth_helper.dart';
import 'user_bookings_screen.dart';
import 'staff_bookings_screen.dart';
import 'business_booking_management_screen.dart';

class ComprehensiveBookingsScreen extends StatefulWidget {
  const ComprehensiveBookingsScreen({super.key});

  @override
  State<ComprehensiveBookingsScreen> createState() => _ComprehensiveBookingsScreenState();
}

class _ComprehensiveBookingsScreenState extends State<ComprehensiveBookingsScreen> with SingleTickerProviderStateMixin {
  // State variables for managing the screen
  bool _isLoading = true;
  String? _errorMessage;

  // User role flags
  bool _isBusinessOwner = false;
  bool _isStaff = false;

  // Tab controller for different views
  TabController? _tabController;

  // Booking data
  List<Map<String, dynamic>> _userBookings = [];
  List<Map<String, dynamic>> _staffBookings = [];

  @override
  void initState() {
    super.initState();
    // Check user roles and load appropriate data
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Initialize screen by checking user roles and setting up tabs
  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check user roles
      final isBusinessOwner = await AuthHelper.isBusinessOwner();
      final isStaff = await AuthHelper.isStaff();

      if (mounted) {
        setState(() {
          _isBusinessOwner = isBusinessOwner;
          _isStaff = isStaff;
        });

        // Set up tab controller based on user roles
        _setupTabController();

        // Load booking data
        await _loadBookingData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking user roles: $e';
        });
      }
    }
  }

  // Set up tab controller based on user roles
  void _setupTabController() {
    int tabCount = 1; // Always have user bookings tab

    if (_isStaff) {
      tabCount++; // Add staff bookings tab
    }

    if (_isBusinessOwner) {
      tabCount++; // Add business management tab
    }

    _tabController = TabController(length: tabCount, vsync: this);
  }

  // Load booking data based on user roles
  Future<void> _loadBookingData() async {
    try {
      // Always load user bookings (customer bookings)
      final userBookingsResult = await GetUserBookingsApi.getUserBookings();

      List<Map<String, dynamic>> staffBookings = [];

      // Load staff bookings if user is staff
      if (_isStaff) {
        final staffBookingsResult = await GetStaffBookingsApi.getStaffBookings();
        if (staffBookingsResult['success']) {
          staffBookings = List<Map<String, dynamic>>.from(staffBookingsResult['bookings'] ?? []);
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (userBookingsResult['success']) {
            _userBookings = List<Map<String, dynamic>>.from(userBookingsResult['bookings'] ?? []);
          } else {
            // Check if token has expired and handle accordingly
            if (AuthHelper.isTokenExpired(userBookingsResult)) {
              AuthHelper.handleTokenExpiration(context);
              return;
            }
            _errorMessage = userBookingsResult['message'] ?? 'Failed to load bookings';
          }

          _staffBookings = staffBookings;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _buildErrorView(),
      );
    }

    // Build tabs based on user roles
    List<Tab> tabs = [
      const Tab(text: 'My Bookings', icon: Icon(Icons.person)),
    ];

    if (_isStaff) {
      tabs.add(const Tab(text: 'Staff Appointments', icon: Icon(Icons.work)));
    }

    if (_isBusinessOwner) {
      tabs.add(const Tab(text: 'Business Management', icon: Icon(Icons.business)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          // Refresh button to reload all data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeScreen,
            tooltip: 'Refresh All Bookings',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabViews(),
      ),
    );
  }

  // Build tab views based on user roles
  List<Widget> _buildTabViews() {
    List<Widget> views = [
      // Always include user bookings view
      _buildUserBookingsView(),
    ];

    if (_isStaff) {
      views.add(_buildStaffBookingsView());
    }

    if (_isBusinessOwner) {
      views.add(_buildBusinessManagementView());
    }

    return views;
  }

  // Build error view when there's an error loading data
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
              onPressed: _initializeScreen,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Build user bookings view (customer bookings)
  Widget _buildUserBookingsView() {
    if (_userBookings.isEmpty) {
      return _buildEmptyBookingsView('You don\'t have any bookings at the moment.');
    }

    return RefreshIndicator(
      onRefresh: _loadBookingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userBookings.length,
        itemBuilder: (context, index) {
          return _buildUserBookingCard(_userBookings[index]);
        },
      ),
    );
  }

  // Build staff bookings view (appointments assigned to staff)
  Widget _buildStaffBookingsView() {
    if (_staffBookings.isEmpty) {
      return _buildEmptyBookingsView('You don\'t have any staff appointments at the moment.');
    }

    return RefreshIndicator(
      onRefresh: _loadBookingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staffBookings.length,
        itemBuilder: (context, index) {
          return _buildStaffBookingCard(_staffBookings[index]);
        },
      ),
    );
  }

  // Build business management view
  Widget _buildBusinessManagementView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 64,
              color: AppStyles.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Business Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access your business booking management from the Business Owner screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/business_owner');
              },
              style: AppStyles.primaryButtonStyle,
              child: const Text('Go to Business Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty bookings view
  Widget _buildEmptyBookingsView(String message) {
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookingData,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Refresh'),
            ),
          ],
        ),
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

  // Build user booking card (customer perspective)
  Widget _buildUserBookingCard(Map<String, dynamic> booking) {
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

  // Build staff booking card (staff perspective - shows customer details)
  Widget _buildStaffBookingCard(Map<String, dynamic> booking) {
    // Extract booking data with safe defaults
    final serviceName = booking['service_name'] ?? 'Unknown Service';
    final businessName = booking['business_name'] ?? 'Unknown Business';
    final customerName = booking['customer_name'] ?? 'Unknown Customer';
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