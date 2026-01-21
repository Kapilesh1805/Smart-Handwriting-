import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Config {
  /// Centralized backend base URL.
  /// Default is localhost equivalent using loopback IP to avoid name resolution issues.
  /// Change `baseUrl` here if you want a different default.
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// API base url getter - uses Android emulator alias when running on Android.
  static String get apiBaseUrl {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {
      // Platform not available or other issue - fallback to baseUrl
    }
    return baseUrl;
  }

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

  static Future<void> saveAuthToken(String token, String userId, {String? userName, String? userEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
    if (userName != null) {
      await prefs.setString('user_name', userName);
    }
    if (userEmail != null) {
      await prefs.setString('user_email', userEmail);
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

  // Log every API call
  print('Calling: ${Config.apiBaseUrl}$endpoint');

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
