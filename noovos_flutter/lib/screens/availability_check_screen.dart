/*
Display availability check for services in the cart
This screen allows users to check if the services in their cart are available
before proceeding to checkout
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/cart_helper.dart';
import 'cart_screen.dart';

class AvailabilityCheckScreen extends StatefulWidget {
  const AvailabilityCheckScreen({super.key});

  @override
  State<AvailabilityCheckScreen> createState() => _AvailabilityCheckScreenState();
}

class _AvailabilityCheckScreenState extends State<AvailabilityCheckScreen> {
  // Loading state
  bool _isLoading = false;
  
  // Selected from date
  DateTime _fromDate = DateTime.now().add(const Duration(days: 1));
  
  // Selected to date
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));
  
  // Time preference
  String _timePreference = 'Any'; // 'Morning', 'Afternoon', or 'Any'
  
  // Cart items
  List<CartItem> _cartItems = [];
  
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
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Check availability (this would be replaced with an API call)
  Future<void> _checkAvailability() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes, we'll just show a message
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature not yet available'),
          duration: Duration(seconds: 2),
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
          
          // From Date selection
          const Text(
            'From Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // From Date picker
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                
                if (pickedDate != null && pickedDate != _fromDate) {
                  setState(() {
                    _fromDate = pickedDate;
                    
                    // Ensure to date is not before from date
                    if (_toDate.isBefore(_fromDate)) {
                      _toDate = _fromDate.add(const Duration(days: 7));
                    }
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
                      _formatDate(_fromDate),
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
          
          // To Date selection
          const Text(
            'To Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // To Date picker
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: _fromDate, // Can't pick a date before from date
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                
                if (pickedDate != null && pickedDate != _toDate) {
                  setState(() {
                    _toDate = pickedDate;
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
                      _formatDate(_toDate),
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
}
