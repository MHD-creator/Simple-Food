import 'package:flutter/material.dart';
import 'package:simple_food/services/cart_service.dart';
import 'package:simple_food/presentations/screens/client_screens/delivery_detail_screen.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon panier")),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService.instance.items,
        builder: (context, list, _) {
          final total = CartService.instance.total;
          if (list.isEmpty) {
            return const Center(child: Text("Votre panier est vide"));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: (item.image.isNotEmpty)
                            ? Image.network(
                                item.image,
                                width: 60,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.fastfood),
                        title: Text(item.name),
                        subtitle: Text(
                          "${item.price.toStringAsFixed(0)} FCFA x ${item.quantity}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  CartService.instance.decrement(item.id),
                              icon: const Icon(Icons.remove),
                            ),
                            Text("${item.quantity}"),
                            IconButton(
                              onPressed: () =>
                                  CartService.instance.increment(item.id),
                              icon: const Icon(Icons.add),
                            ),
                            IconButton(
                              onPressed: () =>
                                  CartService.instance.removeItem(item.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total : ${total.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeliveryDetailScreen(),
                          ),
                        );
                      },
                      child: const Text("Commander"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
