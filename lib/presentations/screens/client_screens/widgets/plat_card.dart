import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/rating_stars.dart';
import 'package:simple_food/services/favorites_service.dart';
import 'package:simple_food/services/cart_service.dart';

class PlatCard extends StatefulWidget {
  final Map<String, dynamic> plat;
  final VoidCallback? onTap;

  const PlatCard({super.key, required this.plat, this.onTap});

  @override
  State<PlatCard> createState() => _PlatCardState();
}

class _PlatCardState extends State<PlatCard> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final id = (widget.plat['id'] ?? '').toString();
    if (id.isEmpty) return;
    final fav = await FavoritesService.isFavorite(id);
    if (!mounted) return;
    setState(() => _isFav = fav);
  }

  Future<void> _toggleFav() async {
    await FavoritesService.toggle({
      'id': widget.plat['id'],
      'nom': widget.plat['nom'],
      'image': widget.plat['image'],
      'prix': widget.plat['prix'],
      'note': widget.plat['note'],
    });
    await _loadFav();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFav ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int stock = (widget.plat['stock'] is int)
        ? (widget.plat['stock'] as int)
        : int.tryParse(widget.plat['stock']?.toString() ?? '0') ?? 0;
    final bool promoActive = (widget.plat['promoActive'] ?? false) == true;
    final double promoPercent = (() {
      final v = widget.plat['promoPercent'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0.0;
    })();
    final double prix = (() {
      final v = widget.plat['prix'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0.0;
    })();
    final double? oldPrix = (() {
      final v = widget.plat['oldPrix'];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    })();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: widget.onTap,
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: Image.network(
                    widget.plat['image'],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                if (promoActive && promoPercent > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${promoPercent.toStringAsFixed(promoPercent % 1 == 0 ? 0 : 0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plat['nom'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    RatingStars(rating: widget.plat['note']),
                    const SizedBox(height: 5),
                    if (promoActive && oldPrix != null && oldPrix > prix)
                      Row(
                        children: [
                          Text(
                            '${prix.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${oldPrix.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      stock > 0 ? 'Stock: $stock' : 'Rupture de stock',
                      style: TextStyle(
                        color: stock > 0 ? Colors.black54 : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ajouter au panier',
                  icon: const Icon(Icons.add_shopping_cart),
                  color: Colors.green,
                  onPressed: stock <= 0
                      ? null
                      : () {
                          try {
                            CartService.instance.addItem(
                              id: (widget.plat['id'] ?? '').toString(),
                              name: widget.plat['nom']?.toString() ?? 'Plat',
                              image: widget.plat['image']?.toString() ?? '',
                              price:
                                  ((widget.plat['prix'] ?? widget.plat['price'])
                                          as num)
                                      .toDouble(),
                              quantity: 1,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ajouté au panier')),
                            );
                          } catch (_) {}
                        },
                ),
                IconButton(
                  icon: Icon(
                    _isFav ? Icons.favorite : Icons.favorite_border,
                    color: _isFav ? Colors.redAccent : null,
                  ),
                  onPressed: _toggleFav,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
