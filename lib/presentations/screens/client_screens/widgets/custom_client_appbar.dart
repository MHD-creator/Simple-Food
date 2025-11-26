import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/favorite_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/panier_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/menu_screen.dart';
import 'package:simple_food/services/cart_service.dart';

PreferredSizeWidget customClientAppBar(
  String pageTitle,
  Color? backgroundColor,
  BuildContext context,
) {
  return AppBar(
    backgroundColor: backgroundColor ?? Color(0xFFFDFBF6),
    title: Text(pageTitle, style: TextStyle(fontWeight: FontWeight.bold)),
    actions: [
      IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.restaurant_menu, color: Colors.green),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavorisScreen()),
        ),
      ),
      ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService.instance.items,
        builder: (context, items, _) {
          final count = items.fold<int>(0, (s, e) => s + e.quantity);
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.orange),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PanierScreen()),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(1.0),
      child: Container(height: 1.0, color: Colors.grey[350]),
    ),
  );
}
