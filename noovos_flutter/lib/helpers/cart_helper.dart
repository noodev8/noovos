/*
Helper class for managing the shopping cart
Stores cart items in memory and provides methods for adding, removing, and retrieving items
*/

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final int serviceId;
  final String serviceName;
  final String businessName;
  final double price;
  final String? serviceImage;
  final int duration;

  CartItem({
    required this.serviceId,
    required this.serviceName,
    required this.businessName,
    required this.price,
    this.serviceImage,
    required this.duration,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'businessName': businessName,
      'price': price,
      'serviceImage': serviceImage,
      'duration': duration,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      businessName: json['businessName'],
      price: json['price'],
      serviceImage: json['serviceImage'],
      duration: json['duration'],
    );
  }
}

class CartHelper {
  // Key for SharedPreferences
  static const String _cartKey = 'cart_items';

  // In-memory cart items
  static List<CartItem> _cartItems = [];
  
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
  static Future<void> addToCart(CartItem item) async {
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
