/*
Display availability check for services in the cart
This screen allows users to check if the services in their cart are available
before proceeding to checkout
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';
import '../helpers/cart_helper.dart';
import '../api/get_service_slot_x1_api.dart';
import 'cart_screen.dart';

class AvailabilityCheckScreen extends StatefulWidget {
  const AvailabilityCheckScreen({super.key});

  @override
  State<AvailabilityCheckScreen> createState() => _AvailabilityCheckScreenState();
}

class _AvailabilityCheckScreenState extends State<AvailabilityCheckScreen> {
  // Loading state
  bool _isLoading = false;

  // Selected date
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  // Time preference
  String _timePreference = 'Any'; // 'Morning', 'Afternoon', or 'Any'

  // Cart items
  List<CartItem> _cartItems = [];

  // Available slots
  List<Map<String, dynamic>> _availableSlots = [];

  // Service details
  Map<String, dynamic>? _serviceDetails;

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Load cart items
    _loadCartItems();
  }

  // Load cart items
  void _loadCartItems() {
    setState(() {
      _cartItems = CartHelper.getCartItems();
    });
  }

  // Format date
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  // Format date for API (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  // Format time (HH:MM:SS to HH:MM AM/PM)
  String _formatTime(String timeString) {
    try {
      // Parse the time string (HH:MM:SS)
      final parts = timeString.split(':');
      if (parts.length < 2) return timeString; // Return original if invalid

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Determine AM/PM
      final period = hour >= 12 ? 'PM' : 'AM';

      // Convert to 12-hour format
      hour = hour % 12;
      if (hour == 0) hour = 12; // 0 should be displayed as 12 in 12-hour format

      // Format the time
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      // Return original string if parsing fails
      return timeString;
    }
  }

  // Check availability using the API
  Future<void> _checkAvailability() async {
    // Reset previous results
    setState(() {
      _isLoading = true;
      _availableSlots = [];
      _serviceDetails = null;
      _errorMessage = null;
    });

    // Check if there are multiple services in the cart
    if (_cartItems.length > 1) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Multiple service availability check is not yet available. Please keep only one service in your cart.';
      });
      return;
    }

    // Check if cart is empty
    if (_cartItems.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Your cart is empty. Please add a service to check availability.';
      });
      return;
    }

    try {
      // Get the first (and only) service from the cart
      final CartItem service = _cartItems.first;

      // Call the API to get available slots
      final result = await GetServiceSlotX1Api.getServiceSlots(
        serviceId: service.serviceId,
        date: _formatDateForApi(_selectedDate),
        staffId: service.staffId,
        timePreference: _timePreference.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Extract data from the response
          final data = result['data'];
          setState(() {
            _serviceDetails = data['service'];
            _availableSlots = List<Map<String, dynamic>>.from(data['slots']);
          });
        } else {
          // Handle error
          setState(() {
            _errorMessage = result['message'];
          });
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Availability'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildAvailabilityCheck(),
    );
  }

  // Build empty cart view
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: AppStyles.subheadingStyle.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add services to your cart to check availability',
              style: AppStyles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: AppStyles.primaryButtonStyle,
              child: const Text('Browse Services'),
            ),
          ],
        ),
      ),
    );
  }

  // Build availability check view
  Widget _buildAvailabilityCheck() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart summary
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  const Text(
                    'Cart Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cart items
                  ..._cartItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Service name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.serviceName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item.businessName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppStyles.secondaryTextColor,
                                ),
                              ),
                              // Staff information
                              Text(
                                item.staffName != null
                                    ? 'Staff: ${item.staffName}'
                                    : 'Staff: Any available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppStyles.secondaryTextColor,
                                  fontStyle: item.staffName != null ? FontStyle.normal : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Duration
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppStyles.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.duration} mins',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),

                        // Price
                        const SizedBox(width: 16),
                        Text(
                          '£${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )),

                  const Divider(),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '£${_cartItems.fold(0.0, (total, item) => total + item.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  // Edit cart button
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        ).then((_) {
                          // Reload cart items when returning from cart screen
                          _loadCartItems();
                        });
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Cart'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Date selection
          const Text(
            'Select Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Date picker
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );

                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                    // Reset results when date changes
                    _availableSlots = [];
                    _serviceDetails = null;
                    _errorMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppStyles.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppStyles.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Time preference selection
          const Text(
            'Time Preference',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Time preference options
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time preference options
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimePreferenceChip('Any'),
                      _buildTimePreferenceChip('Morning'),
                      _buildTimePreferenceChip('Afternoon'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Error message (if any)
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Available slots (if any)
          if (_availableSlots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Available Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._availableSlots.map((slot) => _buildSlotCard(slot)),
            const SizedBox(height: 16),
          ],

          // No slots message (if checked but none found)
          if (_availableSlots.isEmpty && _serviceDetails != null && _errorMessage == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No available slots found for the selected date and time preference. Please try a different date or time preference.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Check availability button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Check Availability'),
            ),
          ),
        ],
      ),
    );
  }

  // Build time preference chip
  Widget _buildTimePreferenceChip(String preference) {
    final bool isSelected = _timePreference == preference;

    return ChoiceChip(
      label: Text(preference),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _timePreference = preference;
            // Reset results when time preference changes
            _availableSlots = [];
            _serviceDetails = null;
            _errorMessage = null;
          }
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? AppStyles.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Build slot card
  Widget _buildSlotCard(Map<String, dynamic> slot) {
    // Extract slot data
    final String startTime = _formatTime(slot['start_time'] ?? '');
    final String endTime = _formatTime(slot['end_time'] ?? '');
    //final int staffId = slot['staff_id'] ?? 0;
    final String staffName = slot['staff_name'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time slot with updated styling
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppStyles.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppStyles.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Staff info
            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: AppStyles.secondaryTextColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Staff: $staffName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              ],
            ),

            // Book button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking functionality coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book This Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

