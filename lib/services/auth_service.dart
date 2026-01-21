import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AuthService {
  /// Login with email and password
  /// Returns: {token, user_id, user_name} on success
  /// Throws: Exception with error message on failure
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Login request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save token, user_id and user_name to local storage
        await Config.saveAuthToken(
          data['token'] as String,
          data['user_id'] as String,
          userName: data['user_name'] as String?,
          userEmail: email,
        );

        return {
          'token': data['token'],
          'user_id': data['user_id'],
          'user_name': data['user_name'],
          'success': true,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException catch (_) {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user account
  /// Returns: {token, user_id, success} on success
  /// Throws: Exception with error message on failure
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Registration request timeout'),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save token, user_id and user_name to local storage
        await Config.saveAuthToken(
          data['token'] as String,
          data['user_id'] as String,
          userName: data['name'] as String?,
          userEmail: email,
        );

        return {
          'token': data['token'],
          'user_id': data['user_id'],
          'name': data['name'],
          'success': true,
        };
      } else if (response.statusCode == 409) {
        throw Exception('Email already registered. Please login instead.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid registration data');
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException catch (_) {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  /// Logout - clears stored credentials
  static Future<void> logout() async {
    await Config.clearAuth();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await Config.isLoggedIn();
  }

  /// Get stored auth token
  static Future<String?> getToken() async {
    return await Config.getAuthToken();
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    return await Config.getUserId();
  }
}

// Import these as needed:
// import 'dart:io';
class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
