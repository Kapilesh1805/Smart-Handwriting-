import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';

/// Child model for type safety
class Child {
  final String childId;
  final String userId;
  final String name;
  final int age;
  final String notes;
  final String? createdAt;
  final String? lastSession;

  Child({
    required this.childId,
    required this.userId,
    required this.name,
    required this.age,
    required this.notes,
    this.createdAt,
    this.lastSession,
  });

  /// Convert JSON response to Child object
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      childId: json['_id'] ?? json['child_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      notes: json['notes'] ?? '',
      createdAt: json['created_at'],
      lastSession: json['last_session'],
    );
  }

  /// Convert Child to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'notes': notes,
    };
  }
}

/// Service for managing child profiles
class ChildService {
  /// Get all children for the current user
  /// Returns: List of Child objects on success
  /// Throws: Exception with error message on failure
  static Future<List<Child>> getChildren({
    required String userId,
  }) async {
    try {
      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/children?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final childrenData = data['children'] as List?;

        if (childrenData == null) {
          return [];
        }

        return childrenData
            .map((child) => Child.fromJson(child as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      } else {
        throw Exception('Failed to fetch children. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Add a new child profile
  /// Returns: Child object with assigned child_id
  /// Throws: Exception with error message on failure
  static Future<Child> addChild({
    required String userId,
    required String name,
    required int age,
    String notes = '',
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw Exception('Child name is required');
      }
      if (name.trim().length < 2) {
        throw Exception('Child name must be at least 2 characters');
      }
      if (age < 1 || age > 18) {
        throw Exception('Age must be between 1 and 18');
      }

      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      final requestBody = {
        'user_id': userId,
        'name': name.trim(),
        'age': age,
        'notes': notes.trim(),
      };

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/children'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Child(
          childId: data['child_id'] ?? '',
          userId: userId,
          name: data['name'] ?? name,
          age: data['age'] ?? age,
          notes: notes,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid data. Please check your input.');
      } else {
        throw Exception('Failed to create child. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Update an existing child profile
  /// Returns: Updated Child object
  /// Throws: Exception with error message on failure
  static Future<Child> updateChild({
    required String childId,
    required String name,
    required int age,
    String notes = '',
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw Exception('Child name is required');
      }
      if (name.trim().length < 2) {
        throw Exception('Child name must be at least 2 characters');
      }
      if (age < 1 || age > 18) {
        throw Exception('Age must be between 1 and 18');
      }

      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      final requestBody = {
        'name': name.trim(),
        'age': age,
        'notes': notes.trim(),
      };

      final response = await http.put(
        Uri.parse('${Config.apiBaseUrl}/children/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      if (response.statusCode == 200) {
        // Return updated child object
        return Child(
          childId: childId,
          userId: '', // We'll get this from context if needed
          name: name,
          age: age,
          notes: notes,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid data. Please check your input.');
      } else {
        throw Exception('Failed to update child. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Delete a child profile
  /// Returns: true on success
  /// Throws: Exception with error message on failure
  static Future<bool> deleteChild({
    required String childId,
  }) async {
    try {
      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      final response = await http.delete(
        Uri.parse('${Config.apiBaseUrl}/children/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found.');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete child. Please try again.');
      }
    } on SocketException catch (_) {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }
}