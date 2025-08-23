import 'package:flutter/material.dart';

// --- DATA MODELS (Single Source of Truth) ---
class ProductVariant {
  final String volume;
  final double price;
  final double? originalPrice;
  ProductVariant({required this.volume, required this.price, this.originalPrice});
}

class Product {
  final String name;
  final String imageUrl;
  final String deliveryTime;
  final String? discount;
  final List<ProductVariant> variants;
  Product({
    required this.name,
    required this.imageUrl,
    this.deliveryTime = '13 MINS',
    this.discount,
    required this.variants,
  });
}

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;
  CartItem({required this.product, required this.variant, this.quantity = 1});

  double get totalPrice => variant.price * quantity;
}

// --- CartManager as a Singleton ---
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() {
    return _instance;
  }
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  double get subtotal {
    double total = 0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  void addItem(Product product, ProductVariant variant) {
    int existingIndex = _items.indexWhere((item) =>
        item.product.name == product.name &&
        item.variant.volume == variant.volume);

    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product, variant: variant));
    }
    notifyListeners();
  }

  void incrementQuantity(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decrementQuantity(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      removeItem(index);
    }
    notifyListeners();
  }
  
  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}