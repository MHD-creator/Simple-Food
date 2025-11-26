import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'client_favorites_v1';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> toggle(Map<String, dynamic> plat) async {
    final list = await getAll();
    final idx = list.indexWhere((e) => e['id'] == plat['id']);
    if (idx == -1) {
      list.add(plat);
    } else {
      list.removeAt(idx);
    }
    await saveAll(list);
  }

  static Future<bool> isFavorite(String id) async {
    final list = await getAll();
    return list.any((e) => e['id'] == id);
  }
}
