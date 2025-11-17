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

  static Future<Map<String, dynamic>> createPlat({
    required String name,
    required String description,
    required double price,
    required String categoryLabel,
    List<String> ingredients = const [],
    required int preparationTime,
    String? image,
    bool? available,
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
        if (available != null) 'available': available,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'success': true,
          'plat': Plat.fromJson(data['data']),
        };
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
      return {
        'success': false,
        'message': message,
        'errors': errors ?? [],
      };
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
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (category != null) 'category': category,
      if (available != null) 'available': available.toString(),
    };
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/plats').replace(queryParameters: params);
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['data'] as List).map((e) => Plat.fromJson(e)).toList();
        return {
          'success': true,
          'data': list,
          'pagination': data['pagination'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMyPlats({int page = 1, int limit = 10}) async {
    try {
      final res = await ApiService.get('/plats/my?page=$page&limit=$limit');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['data'] as List).map((e) => Plat.fromJson(e)).toList();
        return {'success': true, 'data': list, 'pagination': data['pagination']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau', 'error': e.toString()};
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
        final url = (data is Map) ? (data['url'] ?? data['data']?['url']) : null;
        if (url != null) {
          return {'success': true, 'url': url.toString(), 'raw': data};
        }
        return {'success': false, 'message': 'Réponse upload invalide', 'raw': data};
      }
      return {'success': false, 'message': 'Upload échoué', 'raw': res};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau', 'error': e.toString()};
    }
  }
}
