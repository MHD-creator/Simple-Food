import 'package:flutter/foundation.dart';

class CartItem {
  final String id; // plat id
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });
}

class CartService {
  CartService._internal();
  static final CartService instance = CartService._internal();

  final ValueNotifier<List<CartItem>> items = ValueNotifier<List<CartItem>>([]);

  void addItem({
    required String id,
    required String name,
    required String image,
    required double price,
    int quantity = 1,
  }) {
    final list = List<CartItem>.from(items.value);
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx].quantity += quantity;
    } else {
      list.add(
        CartItem(
          id: id,
          name: name,
          image: image,
          price: price,
          quantity: quantity,
        ),
      );
    }
    items.value = list;
  }

  void removeItem(String id) {
    final list = List<CartItem>.from(items.value)
      ..removeWhere((e) => e.id == id);
    items.value = list;
  }

  void increment(String id) {
    final list = List<CartItem>.from(items.value);
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx].quantity += 1;
      items.value = list;
    }
  }

  void decrement(String id) {
    final list = List<CartItem>.from(items.value);
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1 && list[idx].quantity > 1) {
      list[idx].quantity -= 1;
      items.value = list;
    }
  }

  double get total =>
      items.value.fold(0, (sum, e) => sum + e.price * e.quantity);

  void clear() {
    items.value = [];
  }
}
