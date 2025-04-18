/*
Display the shopping cart
This screen shows all services added to the cart
Users can view, remove items, or proceed to checkout
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/cart_helper.dart';
import '../helpers/image_helper.dart';
import 'service_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Cart items
  List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();

    // Get cart items
    _loadCartItems();
  }

  // Load cart items
  void _loadCartItems() {
    setState(() {
      _cartItems = CartHelper.getCartItems();
    });
  }

  // Remove item from cart
  void _removeItem(int serviceId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Remove item
              await CartHelper.removeFromCart(serviceId);

              // Reload cart items
              if (mounted) {
                Navigator.pop(context);
                _loadCartItems();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Clear cart
  void _clearCart() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear cart
              await CartHelper.clearCart();

              // Reload cart items
              if (mounted) {
                Navigator.pop(context);
                _loadCartItems();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // View service details
  void _viewServiceDetails(int serviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceId: serviceId,
        ),
      ),
    ).then((_) {
      // Reload cart items when returning from details screen
      _loadCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate cart total
    final cartTotal = _cartItems.fold(0.0, (total, item) => total + item.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartItems(),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : _buildBottomBar(cartTotal),
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
              'Add services to your cart to book them',
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

  // Build cart items list
  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return _buildCartItemCard(item);
      },
    );
  }

  // Build a cart item card
  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.serviceImage != null
                    ? ImageHelper.getCachedNetworkImage(
                        imageUrl: item.serviceImage!,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.spa,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business name
                  Text(
                    item.businessName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppStyles.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Service name
                  Text(
                    item.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price and duration
                  Row(
                    children: [
                      // Price
                      Text(
                        '£${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),

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
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                // View details button
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _viewServiceDetails(item.serviceId),
                  tooltip: 'View Details',
                  color: AppStyles.primaryColor,
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeItem(item.serviceId),
                  tooltip: 'Remove',
                  color: AppStyles.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build bottom bar with total and checkout button
  Widget _buildBottomBar(double cartTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
                Text(
                  '£${cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Checkout button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement checkout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout functionality coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: AppStyles.primaryButtonStyle,
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
