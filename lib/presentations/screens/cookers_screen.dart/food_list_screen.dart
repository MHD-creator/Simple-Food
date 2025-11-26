import 'dart:io';
import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/add_food_screen.dart';
import 'package:simple_food/models/plat.dart';
import 'package:simple_food/services/plat_service.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/plat_detail_screen.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/reviews_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final List<Plat> plats = [];
  bool _loading = false;
  String? _error;

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
    final res = await PlatService.getMyPlats(page: 1, limit: 50);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        plats
          ..clear()
          ..addAll(((res['data'] as List)).cast<Plat>());
        _loading = false;
      });
    } else {
      // Fallback: charger la liste générale si /plats/my indisponible
      final resAll = await PlatService.getPlats(page: 1, limit: 50);
      if (!mounted) return;
      if (resAll['success'] == true) {
        setState(() {
          plats
            ..clear()
            ..addAll(((resAll['data'] as List)).cast<Plat>());
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message']?.toString() ?? resAll['message']?.toString();
          _loading = false;
        });
      }
    }
  }

  void _ajouterPlat() async {
    final nouveau = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFoodScreen()),
    );
    if (nouveau != null) {
      if (nouveau is Plat) {
        setState(() {
          plats.add(nouveau);
        });
      }
      // Assurer la cohérence avec la base (ex: champs calculés/modifiés côté serveur)
      _loadPlats();
    }
  }

  String _categoryLabelFromEnum(String c) {
    switch (c) {
      case 'boisson':
        return 'Boisson';
      case 'dessert':
        return 'Dessert';
      case 'fast-food':
        return 'Nourriture';
      case 'asiatique':
        return 'Nourriture';
      case 'européen':
        return 'Nourriture';
      default:
        return 'Nourriture';
    }
  }

  void _modifierPlat(Plat plat) async {
    // Convertir en Map attendu par AddFoodScreen
    final mapForEdit = <String, dynamic>{
      'id': plat.id,
      'nom': plat.name,
      'desc': plat.description,
      'categorie': _categoryLabelFromEnum(plat.category),
      'disponible': plat.available,
      'stock': plat.stock,
      'images': <String>[],
      'ingredients': plat.ingredients,
      'preparationTime': plat.preparationTime,
      'prixList': [
        {'label': 'Standard', 'prix': plat.price},
      ],
    };
    final modif = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddFoodScreen(plat: mapForEdit)),
    );
    if (modif != null && modif is Plat) {
      setState(() {
        final index = plats.indexWhere((p) => p.id == plat.id);
        if (index != -1) plats[index] = modif;
      });
    }
  }

  void _supprimerPlat(Plat plat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le plat'),
        content: Text('Voulez-vous vraiment supprimer "${plat.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await PlatService.deletePlat(plat.id);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Plat supprimé')));
                _loadPlats();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res['message']?.toString() ??
                          'Erreur lors de la suppression',
                    ),
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _imageWidget(Plat plat, int index) {
    final tag = 'plat-image-${plat.id}-$index';
    Widget img;
    final src = plat.image;
    if (src != null && src.isNotEmpty) {
      final lower = src.toLowerCase();
      final isHttp =
          lower.startsWith('http://') || lower.startsWith('https://');
      final isLocalFile =
          lower.startsWith('file://') ||
          lower.startsWith('c:') ||
          lower.startsWith('d:') ||
          lower.startsWith('/storage');
      if (isLocalFile) {
        img = Image.file(
          File(src.replaceFirst('file://', '')),
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderBox(),
        );
      } else {
        String url = src;
        if (!isHttp) {
          final origin = _baseOrigin();
          url = src.startsWith('/') ? '$origin$src' : '$origin/$src';
        }
        img = Image.network(
          url,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderBox(),
        );
      }
    } else {
      img = _placeholderBox(width: 70, height: 70);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Hero(tag: tag, child: img),
    );
  }

  String _baseOrigin() {
    final uri = Uri.parse(ApiService.baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Widget _placeholderBox({double width = 70, double height = 70}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEFEFEF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.black26,
        size: 20,
      ),
    );
  }

  String _prixTexte(Plat plat) {
    return "${plat.price.toStringAsFixed(0)} F";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Mes Plats',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterPlat,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("Ajouter un plat"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlats,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : (plats.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Aucun plat disponible',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: plats.length,
                      itemBuilder: (_, i) {
                        final plat = plats[i];
                        final heroTag = 'plat-image-${plat.id}-$i';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            leading: _imageWidget(plat, i),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlatDetailScreen(
                                    plat: plat,
                                    heroTag: heroTag,
                                  ),
                                ),
                              );
                            },
                            title: Text(
                              plat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${_prixTexte(plat)}\n${plat.category} • ${plat.available ? 'Disponible' : 'Indisponible'}\nStock: ${plat.stock}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _modifierPlat(plat);
                                } else if (value == 'delete') {
                                  _supprimerPlat(plat);
                                } else if (value == 'reviews') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlatReviewsScreen(
                                        platId: plat.id,
                                        platName: plat.name,
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reviews',
                                  child: Row(
                                    children: [
                                      Icon(Icons.reviews, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text('Avis'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Supprimer'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
      ),
    );
  }
}
