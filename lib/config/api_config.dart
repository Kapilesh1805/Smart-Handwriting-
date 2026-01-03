import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  // Change this to your backend IP/URL
  // For local testing: http://192.168.x.x:5000 (your machine IP)
  // For production: https://your-backend-domain.com
  static const String apiBaseUrl = 'http://localhost:5000';

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveAuthToken(String token, String userId, {String? userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
    if (userName != null) {
      await prefs.setString('user_name', userName);
    }
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

/// Generic API call helper function
/// Usage: await apiCall('GET', '/endpoint') or await apiCall('POST', '/endpoint', body: {...})
Future<http.Response> apiCall(
  String method,
  String endpoint, {
  dynamic body,
}) async {
  final headers = await Config.getAuthHeaders();
  final url = Uri.parse('${Config.apiBaseUrl}$endpoint');

  try {
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

      case 'POST':
        return await http
            .post(
              url,
              headers: headers,
              body: json.encode(body),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('Request timeout'),
            );

      case 'PUT':
        return await http
            .put(
              url,
              headers: headers,
              body: json.encode(body),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('Request timeout'),
            );

      case 'DELETE':
        return await http.delete(url, headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

      default:
        throw Exception('Unknown HTTP method: $method');
    }
  } catch (e) {
    rethrow;
  }
}
