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
import 'package:simple_food/services/client_plat_service.dart';

class HomeScreenClient extends StatefulWidget {
  const HomeScreenClient({super.key});

  @override
  State<HomeScreenClient> createState() => _HomeScreenClientState();
}

class _HomeScreenClientState extends State<HomeScreenClient> {
  List<Map<String, dynamic>> plats = [];
  bool _loading = false;
  String? _error;
  String selectedCategory = "Tout";
  double _minPrice = 0;
  double _maxPrice = 100000;
  RangeValues _currentRange = const RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _loadPlats();
  }

  Future<void> _loadPlats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ClientPlatService.getPlats(
      categoryLabel: selectedCategory,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        plats = (res['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
        // Calculer min/max des prix (en tenant compte des variantes si présentes)
        if (plats.isNotEmpty) {
          double minP = double.infinity;
          double maxP = 0;
          for (final p in plats) {
            double pMin;
            double pMax;
            final prices = p['prices'] ?? p['prixList'];
            if (prices is List && prices.isNotEmpty) {
              final values = prices.map((e) {
                final pr = (e['price'] ?? e['prix']);
                return pr is num
                    ? pr.toDouble()
                    : double.tryParse(pr?.toString() ?? '') ?? 0.0;
              }).toList();
              pMin = values.reduce((a, b) => a < b ? a : b);
              pMax = values.reduce((a, b) => a > b ? a : b);
            } else {
              final pr = p['prix'] ?? p['price'] ?? 0;
              final v = pr is num
                  ? pr.toDouble()
                  : double.tryParse(pr.toString()) ?? 0.0;
              pMin = v;
              pMax = v;
            }
            if (pMin < minP) minP = pMin;
            if (pMax > maxP) maxP = pMax;
          }
          if (minP == double.infinity) minP = 0;
          _minPrice = minP.floorToDouble();
          _maxPrice = maxP.ceilToDouble();
          // Si la plage actuelle est la plage par défaut, la réinitialiser au nouveau min/max
          if (_currentRange.start == 0 && _currentRange.end == 100000) {
            _currentRange = RangeValues(_minPrice, _maxPrice);
          }
        }
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredPlats = plats.take(3).toList();

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
              _loadPlats();
            },
          ),
          // 💸 Filtre de prix
          if (!_loading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prix: ${_currentRange.start.toStringAsFixed(0)}'),
                  Text('${_currentRange.end.toStringAsFixed(0)} FCFA'),
                ],
              ),
            ),
            RangeSlider(
              min: _minPrice,
              max: (_maxPrice > _minPrice) ? _maxPrice : _minPrice + 1,
              values: _currentRange,
              labels: RangeLabels(
                _currentRange.start.toStringAsFixed(0),
                _currentRange.end.toStringAsFixed(0),
              ),
              onChanged: (values) {
                setState(() => _currentRange = values);
              },
            ),
          ],
          const SizedBox(height: 10),

          // 🍽️ Liste des plats
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                      ? Center(child: Text(_error!))
                      : RefreshIndicator(
                          onRefresh: _loadPlats,
                          child: ListView.builder(
                            itemCount: plats.length,
                            itemBuilder: (context, index) {
                              final plat = plats[index];
                              if (selectedCategory != "Tout" &&
                                  plat['categorie'] != selectedCategory) {
                                return const SizedBox.shrink();
                              }
                              // Appliquer filtre prix (avec variantes)
                              double minPrice;
                              double maxPrice;
                              final prices = plat['prices'] ?? plat['prixList'];
                              if (prices is List && prices.isNotEmpty) {
                                final values = prices.map((e) {
                                  final pr = (e['price'] ?? e['prix']);
                                  return pr is num
                                      ? pr.toDouble()
                                      : double.tryParse(pr?.toString() ?? '') ??
                                            0.0;
                                }).toList();
                                minPrice = values.reduce(
                                  (a, b) => a < b ? a : b,
                                );
                                maxPrice = values.reduce(
                                  (a, b) => a > b ? a : b,
                                );
                              } else {
                                final pr = plat['prix'] ?? plat['price'] ?? 0;
                                final v = pr is num
                                    ? pr.toDouble()
                                    : double.tryParse(pr.toString()) ?? 0.0;
                                minPrice = v;
                                maxPrice = v;
                              }
                              if (maxPrice < _currentRange.start ||
                                  minPrice > _currentRange.end) {
                                return const SizedBox.shrink();
                              }
                              return PlatCard(
                                plat: plat,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlatDetailsScreen(plat: plat),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )),
          ),
        ],
      ),
      bottomNavigationBar: customNavBar(0, null, context),
    );
  }
}
