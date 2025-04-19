/*
Helper class for managing the shopping cart
Stores cart items in memory and provides methods for adding, removing, and retrieving items
*/

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final int serviceId;
  final String serviceName;
  final int businessId;       // Business ID
  final String businessName;
  final double price;
  final String? serviceImage;
  final int duration;
  final int? staffId;         // Optional staff ID (null means any staff)
  final String? staffName;    // Optional staff name

  CartItem({
    required this.serviceId,
    required this.serviceName,
    required this.businessId,
    required this.businessName,
    required this.price,
    this.serviceImage,
    required this.duration,
    this.staffId,             // Optional staff ID
    this.staffName,           // Optional staff name
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'businessId': businessId,
      'businessName': businessName,
      'price': price,
      'serviceImage': serviceImage,
      'duration': duration,
      'staffId': staffId,
      'staffName': staffName,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      businessId: json['businessId'],
      businessName: json['businessName'],
      price: json['price'],
      serviceImage: json['serviceImage'],
      duration: json['duration'],
      staffId: json['staffId'],
      staffName: json['staffName'],
    );
  }
}

class CartHelper {
  // Key for SharedPreferences
  static const String _cartKey = 'cart_items';

  // In-memory cart items
  static List<CartItem> _cartItems = [];

  // Get the current business ID in the cart (or null if cart is empty)
  static int? getCurrentBusinessId() {
    if (_cartItems.isEmpty) return null;
    return _cartItems.first.businessId;
  }

  // Get the current business name in the cart (or null if cart is empty)
  static String? getCurrentBusinessName() {
    if (_cartItems.isEmpty) return null;
    return _cartItems.first.businessName;
  }

  // Check if a service from a specific business can be added to the cart
  static bool canAddToCart(int businessId) {
    // If cart is empty, any business is allowed
    if (_cartItems.isEmpty) {
      return true; // Allow any business ID when cart is empty
    }

    // Get current business ID in cart
    final currentBusinessId = getCurrentBusinessId();

    // If either business ID is 0, require additional validation
    if (businessId == 0 || currentBusinessId == 0) {
      // If both are 0, allow it (same unknown business)
      if (businessId == 0 && currentBusinessId == 0) {
        // Compare business names to ensure they're the same
        final String? currentBusinessName = _cartItems.isNotEmpty ? _cartItems.first.businessName : null;
        return currentBusinessName == null || currentBusinessName.isEmpty;
      }
      // Otherwise, don't allow mixing business ID 0 with other business IDs
      return false;
    }

    // Check if the business matches the current business in the cart
    return businessId == currentBusinessId;
  }

  // Initialize cart from SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);

    if (cartJson != null) {
      try {
        final List<dynamic> cartList = jsonDecode(cartJson);
        _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
      } catch (e) {
        // Handle error silently
        _cartItems = [];
      }
    }
  }

  // Save cart to SharedPreferences
  static Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = _cartItems.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(cartList));
    } catch (e) {
      // Handle error silently
    }
  }

  // Get all cart items
  static List<CartItem> getCartItems() {
    return List.unmodifiable(_cartItems);
  }

  // Add item to cart
  static Future<bool> addToCart(CartItem item) async {
    // Check if the item can be added based on business restrictions
    final canAdd = canAddToCart(item.businessId);

    if (!canAdd) {
      return false; // Cannot add item from a different business
    }

    // Check if item already exists in cart
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.serviceId == item.serviceId);

    if (existingIndex >= 0) {
      // Item already exists, replace it
      _cartItems[existingIndex] = item;
    } else {
      // Add new item
      _cartItems.add(item);
    }

    // Save cart
    await _saveCart();
    return true; // Successfully added
  }

  // Remove item from cart
  static Future<void> removeFromCart(int serviceId) async {
    _cartItems.removeWhere((item) => item.serviceId == serviceId);
    await _saveCart();
  }

  // Clear cart
  static Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
  }

  // Get cart count
  static int getCartCount() {
    return _cartItems.length;
  }

  // Get cart total
  static double getCartTotal() {
    return _cartItems.fold(0, (total, item) => total + item.price);
  }

  // Check if item is in cart
  static bool isInCart(int serviceId) {
    return _cartItems.any((item) => item.serviceId == serviceId);
  }
}
