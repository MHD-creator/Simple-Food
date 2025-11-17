import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simple_food/models/user.dart';
import 'package:simple_food/services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String telephone,
    required String password,
    String role = 'client',
    int? age,
    String? email,
    String? address,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'telephone': telephone,
        'password': password,
        'role': role,
        if (age != null) 'age': age,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Stocker le token
        await ApiService.setToken(responseData['data']['token']);
        
        return {
          'success': true,
          'user': User.fromJson(responseData['data']['user']),
          'token': responseData['data']['token'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'inscription',
          'errors': responseData['errors'] ?? [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'telephone': telephone,
        'password': password,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Stocker le token
        await ApiService.setToken(responseData['data']['token']);
        
        return {
          'success': true,
          'user': User.fromJson(responseData['data']['user']),
          'token': responseData['data']['token'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la connexion',
          'errors': responseData['errors'] ?? [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.get('/auth/profile');

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'user': User.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération du profil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
        'error': e.toString(),
      };
    }
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  static Future<bool> isLoggedIn() async {
    await ApiService.init();
    return ApiService.isAuthenticated;
  }
}
