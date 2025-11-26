import 'dart:convert';
import 'package:simple_food/services/api_service.dart';

class ReviewService {
  static Future<Map<String, dynamic>> postReview({
    required String platId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await ApiService.post('/plats/$platId/reviews', {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      });
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Avis enregistré',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'envoi de l\'avis',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getReviews({
    required String platId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await ApiService.get(
        '/plats/$platId/reviews?page=$page&limit=$limit',
      );
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return {
          'success': true,
          'data': list,
          'pagination': data['pagination'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors du chargement des avis',
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
