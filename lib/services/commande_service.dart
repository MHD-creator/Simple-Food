import 'dart:convert';
import 'package:simple_food/services/api_service.dart';

class CommandeService {
  static Future<Map<String, dynamic>> createCommande({
    required List<Map<String, dynamic>> plats, // [{ plat: id, quantity: n }]
    required String deliveryAddress,
    required String deliveryPhone,
    String? notes,
  }) async {
    try {
      final res = await ApiService.post('/commandes', {
        'plats': plats,
        'deliveryAddress': deliveryAddress,
        'deliveryPhone': deliveryPhone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
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

  static Future<Map<String, dynamic>> getCommandes({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final qp = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final endpoint = Uri(path: '/commandes', queryParameters: qp).toString();
      final res = await ApiService.get(endpoint);
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'],
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

  static Future<Map<String, dynamic>> cancelCommande(String id) async {
    try {
      final res = await ApiService.put('/commandes/$id/cancel', {});
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

  static Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final res = await ApiService.put('/commandes/$id/status', {
        'status': status,
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

  static Future<Map<String, dynamic>> getCommandeById(String id) async {
    try {
      final res = await ApiService.get('/commandes/$id');
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
}
