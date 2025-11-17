import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/favorite_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/panier_screen.dart';

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
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavorisScreen()),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.shopping_cart, color: Colors.orange),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanierScreen()),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(1.0),
      child: Container(height: 1.0, color: Colors.grey[350]),
    ),
  );
}
