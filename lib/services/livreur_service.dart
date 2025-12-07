import 'dart:convert';
import 'package:simple_food/services/api_service.dart';

class LivreurService {
  static Future<Map<String, dynamic>> getLivreurs() async {
    try {
      final res = await ApiService.get('/livreurs');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'success': true,
          'data': (data['data'] as List).cast<Map<String, dynamic>>(),
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

  static Future<Map<String, dynamic>> createLivreur({
    required String name,
    required String telephone,
    required String password,
  }) async {
    try {
      final res = await ApiService.post('/livreurs', {
        'name': name,
        'telephone': telephone,
        'password': password,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': data['data']};
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

  static Future<Map<String, dynamic>> updateLivreur({
    required String id,
    String? name,
    String? telephone,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (telephone != null) 'telephone': telephone,
        if (password != null && password.isNotEmpty) 'password': password,
      };
      final res = await ApiService.put('/livreurs/$id', body);
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': data['data']};
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

  static Future<Map<String, dynamic>> deleteLivreur(String id) async {
    try {
      final res = await ApiService.delete('/livreurs/$id');
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true};
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
}
