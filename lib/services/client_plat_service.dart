import 'package:simple_food/models/plat.dart';
import 'package:simple_food/services/plat_service.dart';
import 'package:simple_food/services/api_service.dart';

class ClientPlatService {
  static Future<Map<String, dynamic>> getPlats({String? categoryLabel}) async {
    String? category;
    if (categoryLabel != null && categoryLabel != 'Tout') {
      // map label to enum used by backend
      switch (categoryLabel.toLowerCase()) {
        case 'boisson':
          category = 'boisson';
          break;
        case 'dessert':
          category = 'dessert';
          break;
        default:
          category = 'fast-food';
      }
    }
    final res = await PlatService.getPlats(
      category: category,
      available: true,
      page: 1,
      limit: 50,
    );
    if (res['success'] == true) {
      String baseOrigin() {
        final uri = Uri.parse(ApiService.baseUrl);
        final port = uri.hasPort ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$port';
      }

      final origin = baseOrigin();
      String normalizeImage(String? src) {
        if (src == null || src.isEmpty) return '';
        final lower = src.toLowerCase();
        final isHttp =
            lower.startsWith('http://') || lower.startsWith('https://');
        final isLocal =
            lower.startsWith('file://') ||
            lower.startsWith('c:') ||
            lower.startsWith('d:') ||
            lower.startsWith('/storage');
        if (isLocal) return src; // not expected on client list but keep
        if (isHttp) return src;
        return src.startsWith('/') ? '$origin$src' : '$origin/$src';
      }

      final now = DateTime.now();
      final list = (res['data'] as List<Plat>).map((p) {
        final bool inWindow =
            (p.promoStart == null || !now.isBefore(p.promoStart!)) &&
            (p.promoEnd == null || !now.isAfter(p.promoEnd!));
        final bool active = p.promoActive && inWindow && (p.promoPercent > 0);
        final double base = p.price;
        final double discounted = active
            ? (base * (1 - (p.promoPercent.clamp(0, 90) / 100))).toDouble()
            : base;
        return {
          'id': p.id,
          'nom': p.name,
          'image': normalizeImage(p.image),
          'prix': discounted,
          'oldPrix': active ? base : null,
          'categorie': p.category,
          'note': p.rating,
          'stock': p.stock,
          'available': p.available,
          'promoActive': active,
          'promoPercent': active ? p.promoPercent : 0.0,
          'promoStart': p.promoStart?.toIso8601String(),
          'promoEnd': p.promoEnd?.toIso8601String(),
        };
      }).toList();
      return {'success': true, 'data': list};
    }
    return {'success': false, 'message': res['message']};
  }

  static Future<Map<String, dynamic>> search(String q) async {
    final res = await PlatService.getPlats(
      q: q,
      available: true,
      page: 1,
      limit: 50,
    );
    if (res['success'] == true) {
      String baseOrigin() {
        final uri = Uri.parse(ApiService.baseUrl);
        final port = uri.hasPort ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$port';
      }

      final origin = baseOrigin();
      String normalizeImage(String? src) {
        if (src == null || src.isEmpty) return '';
        final lower = src.toLowerCase();
        final isHttp =
            lower.startsWith('http://') || lower.startsWith('https://');
        final isLocal =
            lower.startsWith('file://') ||
            lower.startsWith('c:') ||
            lower.startsWith('d:') ||
            lower.startsWith('/storage');
        if (isLocal) return src;
        if (isHttp) return src;
        return src.startsWith('/') ? '$origin$src' : '$origin/$src';
      }

      final now = DateTime.now();
      final list = (res['data'] as List<Plat>).map((p) {
        final bool inWindow =
            (p.promoStart == null || !now.isBefore(p.promoStart!)) &&
            (p.promoEnd == null || !now.isAfter(p.promoEnd!));
        final bool active = p.promoActive && inWindow && (p.promoPercent > 0);
        final double base = p.price;
        final double discounted = active
            ? (base * (1 - (p.promoPercent.clamp(0, 90) / 100))).toDouble()
            : base;
        return {
          'id': p.id,
          'nom': p.name,
          'image': normalizeImage(p.image),
          'prix': discounted,
          'oldPrix': active ? base : null,
          'categorie': p.category,
          'note': p.rating,
          'stock': p.stock,
          'available': p.available,
          'promoActive': active,
          'promoPercent': active ? p.promoPercent : 0.0,
          'promoStart': p.promoStart?.toIso8601String(),
          'promoEnd': p.promoEnd?.toIso8601String(),
        };
      }).toList();
      return {'success': true, 'data': list};
    }
    return {'success': false, 'message': res['message']};
  }
}
