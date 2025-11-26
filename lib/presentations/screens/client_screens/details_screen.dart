import 'package:flutter/material.dart';
import 'widgets/rating_stars.dart';
import 'package:simple_food/services/cart_service.dart';
import 'package:simple_food/services/review_service.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/services/plat_service.dart';
import 'package:simple_food/presentations/screens/client_screens/checkout_modal.dart';

class PlatDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> plat;

  const PlatDetailsScreen({super.key, required this.plat});

  @override
  State<PlatDetailsScreen> createState() => _PlatDetailsScreenState();
}

class _PlatDetailsScreenState extends State<PlatDetailsScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  int _selectedRating = 0; // 1..5
  bool _submitting = false;
  bool _loadingReviews = false;
  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0;
  int _ratingCount = 0;
  int _imgIndex = 0;
  List<String> _images = [];
  List<Map<String, dynamic>> _prices = [];
  int _selectedPrice = 0;
  int _stock = 0;
  bool _promoActive = false;
  double _promoPercent = 0.0;
  DateTime? _promoStart;
  DateTime? _promoEnd;

  @override
  void initState() {
    super.initState();
    _avgRating = (widget.plat['note'] as num?)?.toDouble() ?? 0;
    _ratingCount = 0; // sera mis à jour après chargement des avis
    _loadReviews();
    _loadPlatImages();
    // Pré-remplir variantes de prix à partir de la donnée passée si dispo
    _stock = (widget.plat['stock'] is int)
        ? (widget.plat['stock'] as int)
        : int.tryParse(widget.plat['stock']?.toString() ?? '0') ?? 0;
    // Promo fields depuis la liste si présents
    _promoActive = (widget.plat['promoActive'] ?? false) == true;
    final dynamic rawPercent = widget.plat['promoPercent'];
    _promoPercent = rawPercent is num
        ? rawPercent.toDouble()
        : double.tryParse(rawPercent?.toString() ?? '0') ?? 0.0;
    try {
      final s = widget.plat['promoStart']?.toString();
      final e = widget.plat['promoEnd']?.toString();
      if (s != null && s.isNotEmpty) _promoStart = DateTime.tryParse(s);
      if (e != null && e.isNotEmpty) _promoEnd = DateTime.tryParse(e);
    } catch (_) {}
    final rawPrices = widget.plat['prices'] ?? widget.plat['prixList'];
    if (rawPrices is List) {
      _prices = rawPrices
          .map((e) {
            if (e is Map) {
              final lbl = (e['label'] ?? e['libelle'] ?? '').toString();
              final pr = e['price'] ?? e['prix'];
              final p = pr is num
                  ? pr.toDouble()
                  : double.tryParse(pr?.toString() ?? '') ?? 0.0;
              return {'label': lbl, 'price': p};
            }
            return null;
          })
          .where((e) => e != null && (e!['label'] as String).isNotEmpty)
          .cast<Map<String, dynamic>>()
          .toList();
    }
  }

  Widget _zoomable(Widget child) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(20),
      clipBehavior: Clip.none,
      child: child,
    );
  }

  Future<void> _orderNow() async {
    final id = widget.plat['id']?.toString();
    if (id == null || id.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CheckoutModal(
        overridePlats: [
          {'plat': id, 'quantity': 1},
        ],
      ),
    );
  }

  Future<void> _loadPlatImages() async {
    final id = widget.plat['id']?.toString();
    if (id == null || id.isEmpty) return;
    final res = await PlatService.getPlatById(id);
    if (!mounted) return;
    if (res['success'] == true) {
      final p = res['plat'];
      if (p != null) {
        final List<String> imgs = (p.images as List<String>);
        setState(() {
          _images = imgs;
          // Charger aussi les variantes de prix si renvoyées
          if ((p.prices as List).isNotEmpty) {
            _prices = (p.prices as List)
                .map(
                  (e) => {
                    'label': (e['label'] ?? '').toString(),
                    'price': (e['price'] as num).toDouble(),
                  },
                )
                .toList();
            _selectedPrice = 0;
          }
          // Stock
          final parsedStock = (p.stock is int)
              ? (p.stock as int)
              : int.tryParse(p.stock?.toString() ?? '0') ?? _stock;
          _stock = parsedStock;
          // Promo depuis l'API byId
          _promoActive = p.promoActive == true || _promoActive;
          _promoPercent = (p.promoPercent is num)
              ? (p.promoPercent as num).toDouble()
              : _promoPercent;
          _promoStart = p.promoStart ?? _promoStart;
          _promoEnd = p.promoEnd ?? _promoEnd;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final res = await ReviewService.getReviews(
      platId: widget.plat['id'].toString(),
      page: 1,
      limit: 20,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final list = (res['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _reviews = list;
        _ratingCount = list.length;
        _loadingReviews = false;
      });
    } else {
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une note entre 1 et 5')),
      );
      return;
    }
    setState(() => _submitting = true);
    final res = await ReviewService.postReview(
      platId: widget.plat['id'].toString(),
      rating: _selectedRating,
      comment: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avis enregistré')));
      _commentCtrl.clear();
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _avgRating = (data['rating'] as num?)?.toDouble() ?? _avgRating;
          _ratingCount = (data['ratingCount'] as num?)?.toInt() ?? _ratingCount;
        });
      }
      _loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plat = widget.plat;
    bool isInWindow() {
      final now = DateTime.now();
      final bool afterStart =
          _promoStart == null || !now.isBefore(_promoStart!);
      final bool beforeEnd = _promoEnd == null || !now.isAfter(_promoEnd!);
      return afterStart && beforeEnd;
    }

    bool isPromoActive() => _promoActive && _promoPercent > 0 && isInWindow();
    double currentBasePrice() {
      if (_prices.isNotEmpty) {
        final v = _prices[_selectedPrice]['price'];
        return (v as num).toDouble();
      }
      final v = (plat['prix'] ?? plat['price'] ?? 0);
      return (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    }

    double discounted(double base) {
      final p = _promoPercent.clamp(0, 90);
      return (base * (1 - (p / 100))).toDouble();
    }

    return Scaffold(
      appBar: AppBar(title: Text(plat['nom'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          itemCount: _images.isNotEmpty
                              ? _images.length
                              : (((plat['images'] as List?)?.isNotEmpty ??
                                        false)
                                    ? (plat['images'] as List).length
                                    : 1),
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemBuilder: (context, index) {
                            final List imgsLocal = _images.isNotEmpty
                                ? _images
                                : ((plat['images'] as List?)
                                          ?.map((e) => e.toString())
                                          .toList() ??
                                      const []);
                            final String src = imgsLocal.isNotEmpty
                                ? imgsLocal[index]
                                : (plat['image']?.toString() ?? '');
                            String normalize(String? s) {
                              if (s == null || s.isEmpty) return '';
                              final lower = s.toLowerCase();
                              final isHttp =
                                  lower.startsWith('http://') ||
                                  lower.startsWith('https://');
                              final isLocal =
                                  lower.startsWith('file://') ||
                                  lower.startsWith('c:') ||
                                  lower.startsWith('d:') ||
                                  lower.startsWith('/storage');
                              if (isLocal || isHttp) return s;
                              final uri = Uri.parse(ApiService.baseUrl);
                              final port = uri.hasPort ? ':${uri.port}' : '';
                              final origin = '${uri.scheme}://${uri.host}$port';
                              return s.startsWith('/')
                                  ? '$origin$s'
                                  : '$origin/$s';
                            }

                            final url = normalize(src);
                            if (url.isEmpty) {
                              return _zoomable(
                                Container(
                                  color: const Color(0xFFEFEFEF),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.black26,
                                  ),
                                ),
                              );
                            }
                            return _zoomable(
                              Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFEFEFEF),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Builder(
                        builder: (context) {
                          final int count = _images.isNotEmpty
                              ? _images.length
                              : ((plat['images'] as List?)?.length ?? 0);
                          if (count <= 1) return const SizedBox.shrink();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              count,
                              (i) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _imgIndex
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (isPromoActive())
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${_promoPercent.toStringAsFixed(_promoPercent % 1 == 0 ? 0 : 0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plat['nom'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                RatingStars(rating: _avgRating),
                const SizedBox(width: 8),
                Text('(${_ratingCount})'),
              ],
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final base = currentBasePrice();
                final active = isPromoActive();
                if (active) {
                  final disc = discounted(base);
                  return Row(
                    children: [
                      Text(
                        '${disc.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${base.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.black38,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  );
                }
                return Text(
                  '${base.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              _stock > 0 ? 'Stock: $_stock' : 'Rupture de stock',
              style: TextStyle(
                color: _stock > 0 ? Colors.black54 : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_prices.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "Tailles/variantes",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(_prices.length, (i) {
                  final lbl = (_prices[i]['label'] ?? '').toString();
                  return ChoiceChip(
                    selected: _selectedPrice == i,
                    label: Text(lbl.isEmpty ? 'Option ${i + 1}' : lbl),
                    onSelected: (sel) {
                      setState(() => _selectedPrice = i);
                    },
                    selectedColor: Colors.green.shade100,
                  );
                }),
              ),
            ],
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
              onPressed: _stock <= 0
                  ? null
                  : () {
                      final double base = currentBasePrice();
                      final double priceToUse = isPromoActive()
                          ? discounted(base)
                          : base;
                      final String nameWithVariant = _prices.isNotEmpty
                          ? "${plat['nom'] ?? plat['name']} - ${_prices[_selectedPrice]['label']}"
                          : (plat['nom']?.toString() ?? 'Plat');
                      CartService.instance.addItem(
                        id: plat['id'].toString(),
                        name: nameWithVariant,
                        image: plat['image']?.toString() ?? '',
                        price: priceToUse,
                        quantity: 1,
                      );
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _stock <= 0 ? null : _orderNow,
                icon: const Icon(Icons.flash_on),
                label: const Text('Commander maintenant'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Avis des clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviews.isEmpty)
              const Text('Aucun avis pour le moment')
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final r = _reviews[i];
                  final user = r['user'] as Map<String, dynamic>?;
                  final name = (user?['name'] ?? 'Client').toString();
                  final note = (r['rating'] as num?)?.toInt() ?? 0;
                  final comment = (r['comment'] ?? '').toString();
                  final created = (r['createdAt'] ?? '').toString();
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < note ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (comment.isNotEmpty) Text(comment),
                        Text(
                          created,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            if (ApiService.isAuthenticated) ...[
              const Text('Donnez votre avis'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setState(() => _selectedRating = i + 1),
                    icon: Icon(
                      i < _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitReview,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Envoyer mon avis'),
                ),
              ),
            ] else ...[
              const Text('Connectez-vous pour donner votre avis'),
            ],
          ],
        ),
      ),
    );
  }
}
