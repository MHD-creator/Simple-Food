import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:simple_food/models/plat.dart';
import 'package:simple_food/services/api_service.dart';

class PlatService {
  static const Map<String, String> _categoryMap = {
    // Front label -> backend enum
    'Nourriture': 'africain',
    'Boisson': 'boisson',
    'Dessert': 'dessert',
    'Fast-food': 'fast-food',
    'Asiatique': 'asiatique',
    'Européen': 'européen',
  };

  static String mapCategory(String input) {
    return _categoryMap[input] ?? 'africain';
  }

  static Future<Map<String, dynamic>> getPlatById(String id) async {
    try {
      final res = await ApiService.get('/plats/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'plat': Plat.fromJson(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> createPlat({
    required String name,
    required String description,
    required double price,
    required String categoryLabel,
    List<String> ingredients = const [],
    required int preparationTime,
    String? image,
    List<String>? images,
    List<Map<String, dynamic>>? prices,
    bool? available,
    int? stock,
    bool? promoActive,
    double? promoPercent,
    DateTime? promoStart,
    DateTime? promoEnd,
  }) async {
    final category = mapCategory(categoryLabel);
    try {
      final res = await ApiService.post('/plats', {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'ingredients': ingredients,
        'preparationTime': preparationTime,
        if (image != null) 'image': image,
        if (images != null) 'images': images,
        if (prices != null) 'prices': prices,
        if (available != null) 'available': available,
        if (stock != null) 'stock': stock,
        if (promoActive != null) 'promoActive': promoActive,
        if (promoPercent != null) 'promoPercent': promoPercent,
        if (promoStart != null) 'promoStart': promoStart.toIso8601String(),
        if (promoEnd != null) 'promoEnd': promoEnd.toIso8601String(),
      });
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'plat': Plat.fromJson(data['data'])};
      }
      String message = data['message'] ?? 'Erreur lors de la création du plat';
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'];
        } else if (first is String) {
          message = first;
        }
      }
      return {'success': false, 'message': message, 'errors': errors ?? []};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getPlats({
    String? category,
    bool? available,
    int page = 1,
    int limit = 10,
    String? q,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (category != null) 'category': category,
      if (available != null) 'available': available.toString(),
      if (q != null && q.isNotEmpty) 'q': q,
    };
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/plats',
      ).replace(queryParameters: params);
      final res = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['data'] as List)
            .map((e) => Plat.fromJson(e))
            .toList();
        return {
          'success': true,
          'data': list,
          'pagination': data['pagination'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getMyPlats({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await ApiService.get('/plats/my?page=$page&limit=$limit');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['data'] as List)
            .map((e) => Plat.fromJson(e))
            .toList();
        return {
          'success': true,
          'data': list,
          'pagination': data['pagination'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> uploadImage(File file) async {
    try {
      final res = await ApiService.uploadMultipart(
        endpoint: '/uploads',
        file: file,
        fieldName: 'image',
      );
      final status = res['status'] as int;
      if (status >= 200 && status < 300) {
        final data = res['data'];
        final url = (data is Map)
            ? (data['url'] ?? data['data']?['url'])
            : null;
        if (url != null) {
          return {'success': true, 'url': url.toString(), 'raw': data};
        }
        return {
          'success': false,
          'message': 'Réponse upload invalide',
          'raw': data,
        };
      }
      return {'success': false, 'message': 'Upload échoué', 'raw': res};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updatePlat({
    required String id,
    String? name,
    String? description,
    double? price,
    String? categoryLabel,
    List<String>? ingredients,
    int? preparationTime,
    String? image,
    List<String>? images,
    List<Map<String, dynamic>>? prices,
    bool? available,
    int? stock,
    bool? promoActive,
    double? promoPercent,
    DateTime? promoStart,
    DateTime? promoEnd,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (categoryLabel != null) 'category': mapCategory(categoryLabel),
        if (ingredients != null) 'ingredients': ingredients,
        if (preparationTime != null) 'preparationTime': preparationTime,
        if (image != null) 'image': image,
        if (images != null) 'images': images,
        if (prices != null) 'prices': prices,
        if (available != null) 'available': available,
        if (stock != null) 'stock': stock,
        if (promoActive != null) 'promoActive': promoActive,
        if (promoPercent != null) 'promoPercent': promoPercent,
        if (promoStart != null) 'promoStart': promoStart.toIso8601String(),
        if (promoEnd != null) 'promoEnd': promoEnd.toIso8601String(),
      };
      final res = await ApiService.put('/plats/$id', body);
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'plat': Plat.fromJson(data['data'])};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour du plat',
        'errors': data['errors'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deletePlat(String id) async {
    try {
      final res = await ApiService.delete('/plats/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Suppression échouée',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }
}
