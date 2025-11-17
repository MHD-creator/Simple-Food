class Plat {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? image;
  final String cuisinier;
  final Map<String, dynamic>? cuisinierInfo;
  final List<String> ingredients;
  final bool available;
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
    required this.cuisinier,
    this.cuisinierInfo,
    required this.ingredients,
    required this.available,
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
    final dynamic rawIngredients = json['ingredients'];
    List<String> ingredientsParsed = [];
    if (rawIngredients is List) {
      ingredientsParsed = rawIngredients.map((e) {
        if (e is String) return e;
        if (e is Map) return (e['name'] ?? e['label'] ?? e['value'] ?? e).toString();
        return e.toString();
      }).cast<String>().toList();
    }

    final dynamic rawImage = json['image'];
    String? imageParsed;
    if (rawImage is String) imageParsed = rawImage;
    if (rawImage is Map) imageParsed = (rawImage['url'] ?? rawImage['path'] ?? rawImage['src'])?.toString();

    final dynamic rawCategory = json['category'];
    final String categoryParsed = rawCategory == null ? '' : rawCategory.toString();

    final dynamic rawPrice = json['price'];
    final double priceParsed = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '0') ?? 0;

    final dynamic rawPrep = json['preparationTime'];
    final int prepParsed = rawPrep is int ? rawPrep : int.tryParse(rawPrep?.toString() ?? '0') ?? 0;

    final dynamic rawRating = json['rating'];
    final double ratingParsed = rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '0') ?? 0;

    final dynamic rawRatingCount = json['ratingCount'];
    final int ratingCountParsed = rawRatingCount is int ? rawRatingCount : int.tryParse(rawRatingCount?.toString() ?? '0') ?? 0;

    return Plat(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      price: priceParsed,
      category: categoryParsed,
      image: imageParsed,
      cuisinier: json['cuisinier'] is String
          ? json['cuisinier']
          : ((json['cuisinier'] is Map)
              ? (json['cuisinier']['_id'] ?? json['cuisinier']['id'] ?? json['cuisinier']['name'] ?? '')
              : ''),
      cuisinierInfo: json['cuisinierInfo'] ?? (json['cuisinier'] is Map ? Map<String, dynamic>.from(json['cuisinier']) : null),
      ingredients: ingredientsParsed,
      available: json['available'] ?? true,
      preparationTime: prepParsed,
      rating: ratingParsed,
      ratingCount: ratingCountParsed,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
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
      'cuisinier': cuisinier,
      'ingredients': ingredients,
      'available': available,
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
    String? cuisinier,
    Map<String, dynamic>? cuisinierInfo,
    List<String>? ingredients,
    bool? available,
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
      cuisinier: cuisinier ?? this.cuisinier,
      cuisinierInfo: cuisinierInfo ?? this.cuisinierInfo,
      ingredients: ingredients ?? this.ingredients,
      available: available ?? this.available,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
