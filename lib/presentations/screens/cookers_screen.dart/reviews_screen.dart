import 'package:flutter/material.dart';
import 'package:simple_food/services/review_service.dart';

class PlatReviewsScreen extends StatefulWidget {
  final String platId;
  final String platName;
  const PlatReviewsScreen({
    super.key,
    required this.platId,
    required this.platName,
  });

  @override
  State<PlatReviewsScreen> createState() => _PlatReviewsScreenState();
}

class _PlatReviewsScreenState extends State<PlatReviewsScreen> {
  bool _loading = false;
  String? _error;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _page = 1;
        _hasMore = true;
        _reviews.clear();
      }
    });
    final res = await ReviewService.getReviews(
      platId: widget.platId,
      page: _page,
      limit: _limit,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final List<Map<String, dynamic>> data = (res['data'] as List)
          .cast<Map<String, dynamic>>();
      setState(() {
        _reviews.addAll(data);
        final pagination = res['pagination'] as Map?;
        final pages = (pagination?['pages'] as num?)?.toInt() ?? _page;
        _hasMore = _page < pages;
        _loading = false;
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
      appBar: AppBar(title: Text('Avis • ${widget.platName}')),
      body: RefreshIndicator(
        onRefresh: () => _load(more: false),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reviews.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              );
            }
            final i = index - 1;
            if (i >= _reviews.length) {
              if (_hasMore && !_loading) {
                _page += 1;
                _load(more: true);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _hasMore
                      ? const CircularProgressIndicator()
                      : const Text('Fin des avis'),
                ),
              );
            }
            final r = _reviews[i];
            final user = r['user'] as Map<String, dynamic>?;
            final name = (user?['name'] ?? 'Client').toString();
            final note = (r['rating'] as num?)?.toInt() ?? 0;
            final comment = (r['comment'] ?? '').toString();
            final created = (r['createdAt'] ?? '').toString();
            return Card(
              child: ListTile(
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
              ),
            );
          },
        ),
      ),
    );
  }
}
