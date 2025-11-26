class Plat {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? image;
  final List<String> images;
  final String cuisinier;
  final Map<String, dynamic>? cuisinierInfo;
  final List<String> ingredients;
  final List<Map<String, dynamic>> prices;
  final bool available;
  final int stock;
  final bool promoActive;
  final double promoPercent;
  final DateTime? promoStart;
  final DateTime? promoEnd;
  final int preparationTime;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plat({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.image,
    this.images = const [],
    required this.cuisinier,
    this.cuisinierInfo,
    required this.ingredients,
    this.prices = const [],
    required this.available,
    required this.stock,
    this.promoActive = false,
    this.promoPercent = 0.0,
    this.promoStart,
    this.promoEnd,
    required this.preparationTime,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic v) {
    if (v is String) {
      return DateTime.parse(v);
    }
    if (v is int) {
      // Assume milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is Map) {
      // Handle MongoDB-like {'$date': '...'} or {'date': '...'}
      final dynamic inner = v['\$date'] ?? v['date'] ?? v['iso'] ?? v['value'];
      if (inner is String) return DateTime.parse(inner);
      if (inner is int) return DateTime.fromMillisecondsSinceEpoch(inner);
    }
    // Fallback: now
    return DateTime.now();
  }

  factory Plat.fromJson(Map<String, dynamic> json) {
    final dynamic rawIngredients =
        json['ingredients'] ?? json['ingrédients'] ?? json['ingredientsList'];
    List<String> ingredientsParsed = [];
    if (rawIngredients is List) {
      ingredientsParsed = rawIngredients
          .map((e) {
            if (e is String) return e;
            if (e is Map)
              return (e['name'] ?? e['label'] ?? e['value'] ?? e['nom'] ?? e)
                  .toString();
            return e.toString();
          })
          .cast<String>()
          .toList();
    }

    // Images: accepter 'image' (string/map) et liste 'images'
    String? imageParsed;
    List<String> imagesParsed = [];
    final dynamic rawImage = json['image'] ?? json['cover'] ?? json['photo'];
    if (json['images'] is List) {
      imagesParsed = (json['images'] as List)
          .map((e) {
            if (e is String) return e;
            if (e is Map)
              return (e['url'] ?? e['path'] ?? e['src'] ?? '').toString();
            return e?.toString() ?? '';
          })
          .where((e) => e.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (rawImage is String && rawImage.isNotEmpty) {
      imageParsed = rawImage;
    } else if (rawImage is Map) {
      imageParsed = (rawImage['url'] ?? rawImage['path'] ?? rawImage['src'])
          ?.toString();
    }
    if ((imageParsed == null || imageParsed.isEmpty) &&
        imagesParsed.isNotEmpty) {
      imageParsed = imagesParsed.first;
    }

    // Catégorie et prix avec variantes FR
    final dynamic rawCategory =
        json['category'] ?? json['categorie'] ?? json['type'];
    final String categoryParsed = rawCategory == null
        ? ''
        : rawCategory.toString();

    final dynamic rawPrice = json['price'] ?? json['prix'];
    final double priceParsed = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0;

    // Variantes de prix: accepter 'prices' ou 'prixList'
    List<Map<String, dynamic>> pricesParsed = [];
    final dynamic rawPrices = json['prices'] ?? json['prixList'];
    if (rawPrices is List) {
      pricesParsed = rawPrices
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

    // Temps de préparation avec variantes FR
    final dynamic rawPrep =
        json['preparationTime'] ??
        json['tempsPreparation'] ??
        json['temps_preparation'];
    final int prepParsed = rawPrep is int
        ? rawPrep
        : int.tryParse(rawPrep?.toString() ?? '0') ?? 0;

    final dynamic rawRating = json['rating'] ?? json['note'];
    final double ratingParsed = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '0') ?? 0;

    final dynamic rawRatingCount =
        json['ratingCount'] ?? json['nbAvis'] ?? json['reviewsCount'];
    final int ratingCountParsed = rawRatingCount is int
        ? rawRatingCount
        : int.tryParse(rawRatingCount?.toString() ?? '0') ?? 0;

    // Stock
    final dynamic rawStock = json['stock'];
    final int stockParsed = rawStock is int
        ? rawStock
        : int.tryParse(rawStock?.toString() ?? '0') ?? 0;

    // Promo fields
    final bool promoActiveParsed = (json['promoActive'] ?? false) == true;
    final dynamic rawPromoPercent =
        json['promoPercent'] ?? json['discount'] ?? 0;
    final double promoPercentParsed = rawPromoPercent is num
        ? rawPromoPercent.toDouble()
        : double.tryParse(rawPromoPercent?.toString() ?? '0') ?? 0.0;
    final DateTime? promoStartParsed = json['promoStart'] != null
        ? _parseDate(json['promoStart'])
        : null;
    final DateTime? promoEndParsed = json['promoEnd'] != null
        ? _parseDate(json['promoEnd'])
        : null;

    // Dates: accepter plusieurs clés
    final dynamic createdRaw =
        json['createdAt'] ?? json['created_at'] ?? json['created'];
    final dynamic updatedRaw =
        json['updatedAt'] ?? json['updated_at'] ?? json['updated'];

    // Champs requis avec fallback pour éviter les crashs
    final String idParsed = (json['_id'] ?? json['id'] ?? json['uuid'] ?? '')
        .toString();
    final String nameParsed =
        (json['name'] ?? json['nom'] ?? json['title'] ?? '').toString();
    final String descParsed =
        (json['description'] ?? json['desc'] ?? json['details'] ?? '')
            .toString();

    return Plat(
      id: idParsed.isEmpty ? 'unknown' : idParsed,
      name: nameParsed.isEmpty ? 'Sans nom' : nameParsed,
      description: descParsed,
      price: priceParsed,
      category: categoryParsed,
      image: imageParsed,
      images: imagesParsed,
      cuisinier: json['cuisinier'] is String
          ? json['cuisinier']
          : ((json['cuisinier'] is Map)
                ? (json['cuisinier']['_id'] ??
                      json['cuisinier']['id'] ??
                      json['cuisinier']['name'] ??
                      json['cuisinier']['nom'] ??
                      '')
                : ''),
      cuisinierInfo:
          json['cuisinierInfo'] ??
          (json['cuisinier'] is Map
              ? Map<String, dynamic>.from(json['cuisinier'])
              : null),
      ingredients: ingredientsParsed,
      prices: pricesParsed,
      available: (json['available'] ?? json['disponible'] ?? true) == true,
      stock: stockParsed,
      promoActive: promoActiveParsed,
      promoPercent: promoPercentParsed,
      promoStart: promoStartParsed,
      promoEnd: promoEndParsed,
      preparationTime: prepParsed,
      rating: ratingParsed,
      ratingCount: ratingCountParsed,
      createdAt: _parseDate(createdRaw),
      updatedAt: _parseDate(updatedRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'images': images,
      'cuisinier': cuisinier,
      'ingredients': ingredients,
      'prices': prices,
      'available': available,
      'stock': stock,
      'promoActive': promoActive,
      'promoPercent': promoPercent,
      'promoStart': promoStart?.toIso8601String(),
      'promoEnd': promoEnd?.toIso8601String(),
      'preparationTime': preparationTime,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Plat copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? image,
    List<String>? images,
    String? cuisinier,
    Map<String, dynamic>? cuisinierInfo,
    List<String>? ingredients,
    List<Map<String, dynamic>>? prices,
    bool? available,
    int? stock,
    bool? promoActive,
    double? promoPercent,
    DateTime? promoStart,
    DateTime? promoEnd,
    int? preparationTime,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      images: images ?? this.images,
      cuisinier: cuisinier ?? this.cuisinier,
      cuisinierInfo: cuisinierInfo ?? this.cuisinierInfo,
      ingredients: ingredients ?? this.ingredients,
      prices: prices ?? this.prices,
      available: available ?? this.available,
      stock: stock ?? this.stock,
      promoActive: promoActive ?? this.promoActive,
      promoPercent: promoPercent ?? this.promoPercent,
      promoStart: promoStart ?? this.promoStart,
      promoEnd: promoEnd ?? this.promoEnd,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
