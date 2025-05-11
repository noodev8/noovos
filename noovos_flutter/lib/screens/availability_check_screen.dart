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
import '../api/get_service_slot_x2_api.dart';
import '../api/get_service_slot_x3_api.dart';
import '../api/create_booking_api.dart';
import 'cart_screen.dart';
import 'booking_confirmation_screen.dart';

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

    // Check if there are more than 3 services in the cart (should never happen with our new limit)
    if (_cartItems.length > CartHelper.maxCartItems) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You have exceeded the maximum number of services allowed (${CartHelper.maxCartItems}). Please remove some items from your cart.';
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
      Map<String, dynamic> result;

      // Call the appropriate API based on number of services
      switch (_cartItems.length) {
        case 1:
          // Single service
          result = await GetServiceSlotX1Api.getServiceSlots(
            serviceId: _cartItems[0].serviceId,
            date: _formatDateForApi(_selectedDate),
            staffId: _cartItems[0].staffId,
            timePreference: _timePreference.toLowerCase(),
          );
          break;

        case 2:
          // Two services
          result = await GetServiceSlotX2Api.getServiceSlots(
            serviceId1: _cartItems[0].serviceId,
            serviceId2: _cartItems[1].serviceId,
            date: _formatDateForApi(_selectedDate),
            staffId1: _cartItems[0].staffId,
            staffId2: _cartItems[1].staffId,
            timePreference: _timePreference.toLowerCase(),
          );
          break;

        case 3:
          // Three services
          result = await GetServiceSlotX3Api.getServiceSlots(
            serviceId1: _cartItems[0].serviceId,
            serviceId2: _cartItems[1].serviceId,
            serviceId3: _cartItems[2].serviceId,
            date: _formatDateForApi(_selectedDate),
            staffId1: _cartItems[0].staffId,
            staffId2: _cartItems[1].staffId,
            staffId3: _cartItems[2].staffId,
            timePreference: _timePreference.toLowerCase(),
          );
          break;

        default:
          throw Exception('Invalid number of services in cart');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Extract data from the response
          final data = result['data'];
          setState(() {
            // For single service, use 'service' field
            // For multiple services, use 'services' field
            _serviceDetails = _cartItems.length == 1 ? data['service'] : data['services'];
            // For single service, use 'slots' field
            // For multiple services, use 'combined_slots' field
            _availableSlots = List<Map<String, dynamic>>.from(
              _cartItems.length == 1 ? data['slots'] : data['combined_slots']
            );
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

  // Create booking
  Future<void> _createBooking(Map<String, dynamic> slot) async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // For multiple services, we need to create bookings for each service
      if (_cartItems.length > 1) {
        // Get the services in the correct order based on the slot data
        List<CartItem> orderedServices = _cartItems;
        if (_cartItems.length == 2 && slot['order'] == '2-1') {
          // For x2 API, if order is 2-1, swap the services
          orderedServices = [_cartItems[1], _cartItems[0]];
        }

        // Create bookings for each service
        for (int i = 0; i < orderedServices.length; i++) {
          final service = orderedServices[i];
          final serviceSlot = slot['service_${i + 1}'];

          // Format times to HH:MM format
          String startTime = serviceSlot['start_time'].toString().substring(0, 5);
          String endTime = serviceSlot['end_time'].toString().substring(0, 5);

          // Call the API to create the booking
          final result = await CreateBookingApi.createBooking(
            serviceId: service.serviceId,
            staffId: serviceSlot['staff_id'],
            bookingDate: _formatDateForApi(_selectedDate),
            startTime: startTime,
            endTime: endTime,
          );

          if (!result['success']) {
            throw Exception(result['message'] ?? 'Failed to create booking');
          }
        }

        // Clear the cart
        CartHelper.clearCart();

        // Navigate to booking confirmation screen with the last booking details
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookingConfirmationScreen(
                bookingDetails: slot,
              ),
            ),
          );
        }
      } else {
        // Single service booking (existing code)
        final CartItem service = _cartItems.first;

        // Format times to HH:MM format
        String startTime = slot['start_time'].toString().substring(0, 5);
        String endTime = slot['end_time'].toString().substring(0, 5);

        // Call the API to create the booking
        final result = await CreateBookingApi.createBooking(
          serviceId: service.serviceId,
          staffId: slot['staff_id'],
          bookingDate: _formatDateForApi(_selectedDate),
          startTime: startTime,
          endTime: endTime,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success']) {
            // Clear the cart
            CartHelper.clearCart();

            // Navigate to booking confirmation screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingConfirmationScreen(
                    bookingDetails: result['data'],
                  ),
                ),
              );
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to create booking'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _createBooking(slot),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // For multiple services, show each service's details
              if (_cartItems.length > 1) ...[
                for (int i = 0; i < _cartItems.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _buildServiceSlotDetails(
                    service: _cartItems[i],
                    slot: slot['service_${i + 1}'],
                    isLast: i == _cartItems.length - 1,
                  ),
                ],
                const SizedBox(height: 16),
                // Show total duration
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppStyles.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Duration: ${slot['total_duration']} minutes',
                      style: const TextStyle(
                        color: AppStyles.secondaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Single service slot details
                _buildServiceSlotDetails(
                  service: _cartItems[0],
                  slot: slot,
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build service slot details
  Widget _buildServiceSlotDetails({
    required CartItem service,
    required Map<String, dynamic> slot,
    required bool isLast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service name
        Text(
          service.serviceName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Time and staff
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: AppStyles.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatTime(slot['start_time'])} - ${_formatTime(slot['end_time'])}',
              style: const TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.person,
              size: 16,
              color: AppStyles.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              slot['staff_name'] ?? 'Any Staff',
              style: const TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: AppStyles.secondaryTextColor,
              ),
              SizedBox(width: 8),
              Text(
                'Followed by',
                style: TextStyle(
                  color: AppStyles.secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}


