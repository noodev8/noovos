/*
Display availability check for services in the cart
This screen allows users to check if the services in their cart are available
before proceeding to checkout
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/cart_helper.dart';
import '../api/get_service_api.dart';
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
  
  // Available time slots
  List<TimeOfDay> _availableTimeSlots = [];
  
  // Selected time slot
  TimeOfDay? _selectedTimeSlot;
  
  // Cart items
  List<CartItem> _cartItems = [];
  
  @override
  void initState() {
    super.initState();
    
    // Load cart items
    _loadCartItems();
    
    // Generate dummy time slots for now
    _generateDummyTimeSlots();
  }
  
  // Load cart items
  void _loadCartItems() {
    setState(() {
      _cartItems = CartHelper.getCartItems();
    });
  }
  
  // Generate dummy time slots (this would be replaced with an API call)
  void _generateDummyTimeSlots() {
    // Generate time slots from 9 AM to 5 PM with 30-minute intervals
    final List<TimeOfDay> slots = [];
    
    for (int hour = 9; hour < 17; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      slots.add(TimeOfDay(hour: hour, minute: 30));
    }
    
    setState(() {
      _availableTimeSlots = slots;
    });
  }
  
  // Format time of day
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Check availability (this would be replaced with an API call)
  Future<void> _checkAvailability() async {
    if (_selectedTimeSlot == null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes, we'll just show a success message
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Services Available!'),
          content: Text(
            'The selected services are available on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_formatTimeOfDay(_selectedTimeSlot!)}.\n\n'
            'Would you like to proceed to checkout?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to checkout screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout functionality coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primaryColor,
              ),
              child: const Text('Proceed to Checkout'),
            ),
          ],
        ),
      );
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
                  )).toList(),
                  
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
                    _selectedTimeSlot = null; // Reset selected time slot
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
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
          
          // Time slot selection
          const Text(
            'Select Time Slot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Time slots grid
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Morning slots
                  const Text(
                    'Morning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTimeSlots
                        .where((slot) => slot.hour < 12)
                        .map((slot) => _buildTimeSlotChip(slot))
                        .toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Afternoon slots
                  const Text(
                    'Afternoon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTimeSlots
                        .where((slot) => slot.hour >= 12)
                        .map((slot) => _buildTimeSlotChip(slot))
                        .toList(),
                  ),
                ],
              ),
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
  
  // Build time slot chip
  Widget _buildTimeSlotChip(TimeOfDay timeSlot) {
    final bool isSelected = _selectedTimeSlot == timeSlot;
    
    return ChoiceChip(
      label: Text(_formatTimeOfDay(timeSlot)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeSlot = selected ? timeSlot : null;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppStyles.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppStyles.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
