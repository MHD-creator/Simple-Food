import 'dart:io';
import 'package:flutter/material.dart';
import 'package:simple_food/models/plat.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/services/review_service.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/rating_stars.dart';

class PlatDetailScreen extends StatefulWidget {
  final Plat plat;
  final String? heroTag;
  const PlatDetailScreen({super.key, required this.plat, this.heroTag});

  @override
  State<PlatDetailScreen> createState() => _PlatDetailScreenState();
}

class _PlatDetailScreenState extends State<PlatDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  int _selectedRating = 0; // 1..5
  bool _submitting = false;
  bool _loadingReviews = false;
  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0;
  int _ratingCount = 0;
  int _imgIndex = 0;

  @override
  void initState() {
    super.initState();
    _avgRating = widget.plat.rating;
    _ratingCount = widget.plat.ratingCount;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final res = await ReviewService.getReviews(
      platId: widget.plat.id,
      page: 1,
      limit: 20,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _reviews = (res['data'] as List).cast<Map<String, dynamic>>();
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
      platId: widget.plat.id,
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
    final tag = (widget.heroTag != null && widget.heroTag!.isNotEmpty)
        ? widget.heroTag!
        : 'plat-image-${widget.plat.id}';
    // Carousel d'images
    Widget imageCarousel = SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: widget.plat.images.isNotEmpty
                  ? widget.plat.images.length
                  : 1,
              onPageChanged: (i) => setState(() => _imgIndex = i),
              itemBuilder: (context, index) {
                final String src = widget.plat.images.isNotEmpty
                    ? widget.plat.images[index]
                    : (widget.plat.image ?? '');
                String normalize(String s) {
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
                  final origin = _baseOrigin();
                  return s.startsWith('/') ? '$origin$s' : '$origin/$s';
                }

                if (src.isEmpty) {
                  return _placeholderBanner();
                }
                final lower = src.toLowerCase();
                final isLocalFile =
                    lower.startsWith('file://') ||
                    lower.startsWith('c:') ||
                    lower.startsWith('d:') ||
                    lower.startsWith('/storage');
                if (isLocalFile) {
                  return Image.file(
                    File(src.replaceFirst('file://', '')),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderBanner(),
                  );
                }
                final url = normalize(src);
                return Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderBanner(),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          if (widget.plat.images.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.plat.images.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _imgIndex ? Colors.green : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.plat.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: imageCarousel,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plat.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.plat.price.toStringAsFixed(0)} F",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.plat.category,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.plat.preparationTime} min",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.plat.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingStars(rating: _avgRating),
                      const SizedBox(width: 8),
                      Text('(${_ratingCount})'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        widget.plat.available
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: widget.plat.available
                            ? Colors.green
                            : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.plat.available ? 'Disponible' : 'Indisponible',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stock: ${widget.plat.stock}',
                        style: TextStyle(
                          color: widget.plat.stock > 0
                              ? Colors.black87
                              : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Avis (public list + form for authenticated users)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                          onPressed: () =>
                              setState(() => _selectedRating = i + 1),
                          icon: Icon(
                            i < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
          ],
        ),
      ),
    );
  }

  String _baseOrigin() {
    final uri = Uri.parse(ApiService.baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Widget _placeholderBanner() {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFFEFEFEF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.black26,
        size: 40,
      ),
    );
  }
}
