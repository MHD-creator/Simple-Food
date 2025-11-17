import 'package:flutter/material.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final List<Map<String, dynamic>> panier = [
    {
      'nom': 'Poulet braisé',
      'prix': 2500,
      'quantite': 1,
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
    },
    {
      'nom': 'Jus de bissap',
      'prix': 1000,
      'quantite': 2,
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
    },
  ];

  double get total =>
      panier.fold(0, (sum, item) => sum + (item['prix'] * item['quantite']));

  void incrementQuantite(int index) {
    setState(() {
      panier[index]['quantite']++;
    });
  }

  void decrementQuantite(int index) {
    setState(() {
      if (panier[index]['quantite'] > 1) panier[index]['quantite']--;
    });
  }

  void supprimerArticle(int index) {
    setState(() {
      panier.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon panier")),
      body: panier.isEmpty
          ? const Center(child: Text("Votre panier est vide"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: panier.length,
                    itemBuilder: (context, index) {
                      final item = panier[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Image.network(item['image'], width: 60),
                          title: Text(item['nom']),
                          subtitle: Text(
                            "${item['prix']} FCFA x ${item['quantite']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => decrementQuantite(index),
                                icon: const Icon(Icons.remove),
                              ),
                              Text("${item['quantite']}"),
                              IconButton(
                                onPressed: () => incrementQuantite(index),
                                icon: const Icon(Icons.add),
                              ),
                              IconButton(
                                onPressed: () => supprimerArticle(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
                        "Total : $total FCFA",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Commande validée avec succès !"),
                            ),
                          );
                        },
                        child: const Text("Commander"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
