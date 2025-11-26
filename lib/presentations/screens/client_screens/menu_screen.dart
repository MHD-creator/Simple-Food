import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/category_filter.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/plat_card.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/services/client_plat_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = 'Tout';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> plats = [];
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
        // Calcul min/max en tenant compte des variantes
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
          if (_currentRange.start == 0 && _currentRange.end == 100000) {
            _currentRange = RangeValues(_minPrice, _maxPrice);
          }
        }
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customClientAppBar('Menu', null, context),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                Text(
                  'Choisissez une catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CategorieFilter(
            selected: selectedCategory,
            onSelect: (cat) {
              setState(() => selectedCategory = cat);
              _loadPlats();
            },
          ),
          // Filtre de prix
          if (!_loading) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
                              // Appliquer le filtre par catégorie
                              if (selectedCategory != 'Tout' &&
                                  plat['categorie'] != selectedCategory) {
                                return const SizedBox.shrink();
                              }
                              // Appliquer le filtre de prix (avec variantes)
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
