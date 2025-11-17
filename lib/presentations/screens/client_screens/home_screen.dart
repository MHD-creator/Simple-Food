import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/favorite_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/panier_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/recherches_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/category_filter.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/plat_card.dart';

class HomeScreenClient extends StatefulWidget {
  const HomeScreenClient({super.key});

  @override
  State<HomeScreenClient> createState() => _HomeScreenClientState();
}

class _HomeScreenClientState extends State<HomeScreenClient> {
  final List<Map<String, dynamic>> plats = [
    {
      'id': 1,
      'nom': 'Poulet braisé',
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589375939?alt=media&token=d841a60f-a643-4f97-9f7c-189aae4050a2',
      'prix': 2500,
      'categorie': 'Nourriture',
      'note': 4.5,
    },
    {
      'id': 2,
      'nom': 'Jus de bissap',
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
      'prix': 1000,
      'categorie': 'Boisson',
      'note': 4.8,
    },
    {
      'id': 3,
      'nom': 'Riz au gras',
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589375939?alt=media&token=d841a60f-a643-4f97-9f7c-189aae4050a2',
      'prix': 3000,
      'categorie': 'Nourriture',
      'note': 4.3,
    },
  ];

  String selectedCategory = "Tout";

  @override
  Widget build(BuildContext context) {
    final featuredPlats = plats.take(3).toList(); // plats vedettes

    return Scaffold(
      appBar: customClientAppBar('Simple Food', null, context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              readOnly: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RechercheScreen()),
              ),
              decoration: InputDecoration(
                hintText: "Rechercher un plat...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🎠 Carrousel de plats vedettes
          CarouselSlider.builder(
            itemCount: featuredPlats.length,
            itemBuilder: (context, index, realIndex) {
              final plat = featuredPlats[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlatDetailsScreen(plat: plat),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        plat['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plat['nom'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${plat['prix']} FCFA",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlatDetailsScreen(plat: plat),
                              ),
                            ),
                            child: const Text("Voir détail"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 180,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              aspectRatio: 16 / 9,
              autoPlayInterval: const Duration(seconds: 4),
            ),
          ),

          const SizedBox(height: 10),

          // 🏷️ Filtres par catégorie
          CategorieFilter(
            selected: selectedCategory,
            onSelect: (cat) {
              setState(() {
                selectedCategory = cat;
              });
            },
          ),
          const SizedBox(height: 10),

          // 🍽️ Liste des plats
          Expanded(
            child: ListView.builder(
              itemCount: plats.length,
              itemBuilder: (context, index) {
                final plat = plats[index];
                if (selectedCategory != "Tout" &&
                    plat['categorie'] != selectedCategory) {
                  return const SizedBox.shrink();
                }
                return PlatCard(
                  plat: plat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlatDetailsScreen(plat: plat),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: customNavBar(0, null, context),
    );
  }
}
