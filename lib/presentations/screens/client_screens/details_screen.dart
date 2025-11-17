import 'package:flutter/material.dart';
import 'widgets/rating_stars.dart';

class PlatDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> plat;

  const PlatDetailsScreen({super.key, required this.plat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plat['nom'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(plat['image'], fit: BoxFit.cover),
            const SizedBox(height: 10),
            Text(
              plat['nom'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            RatingStars(rating: plat['note']),
            const SizedBox(height: 10),
            Text(
              "${plat['prix']} FCFA",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Description du plat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              "Ce plat est préparé avec soin par nos meilleurs cuisiniers. "
              "Les ingrédients sont frais et sélectionnés pour leur qualité.",
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ajouté au panier !")),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Ajouter au panier"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
