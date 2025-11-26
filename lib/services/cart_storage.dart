import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_service.dart';

class CartStorage {
  static const _key = 'client_cart_items_v1';

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final items = CartService.instance.items.value
        .map(
          (e) => {
            'id': e.id,
            'name': e.name,
            'image': e.image,
            'price': e.price,
            'quantity': e.quantity,
          },
        )
        .toList();
    await prefs.setString(_key, jsonEncode(items));
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map(
            (m) => CartItem(
              id: m['id'],
              name: m['name'],
              image: m['image'] ?? '',
              price: (m['price'] as num).toDouble(),
              quantity: (m['quantity'] as num).toInt(),
            ),
          )
          .toList();
      CartService.instance.items.value = list;
    } catch (_) {}
  }
}
