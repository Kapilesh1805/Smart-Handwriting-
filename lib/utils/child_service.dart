import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/child_profile.dart';
import '../config/api_config.dart';

class ChildService {
  // Use Config.apiBaseUrl instead of hardcoding

  // Fetch all children from backend
  static Future<List<ChildProfile>> fetchChildren() async {
    try {
      debugPrint('📚 Fetching children from backend...');
      
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/child/get_all'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final childrenData = jsonData['data'] as List<dynamic>? ?? [];
        
        debugPrint('✅ Loaded ${childrenData.length} children from backend');
        
        return childrenData.map((child) {
          return ChildProfile(
            id: child['_id']?.toString() ?? child['id']?.toString() ?? '',
            name: child['name'] ?? 'Unknown',
            age: child['age']?.toString() ?? '0',
            grade: child['grade'] ?? 'N/A',
            avatar: child['avatar'] ?? '👧',
            lastAssessment: child['last_assessment'],
            assessmentStatus: child['assessment_status'],
          );
        }).toList();
      } else {
        debugPrint('⚠️ Failed to fetch children: ${response.statusCode}');
        return [];
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error: $e');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching children: $e');
      return [];
    }
  }

  // Add new child
  static Future<ChildProfile> addChild({
    required String name,
    required String age,
    required String grade,
    required String avatar,
  }) async {
    try {
      debugPrint('➕ Adding new child: $name');
      
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/child/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'age': int.tryParse(age) ?? 0,
          'grade': grade,
          'avatar': avatar,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final childData = jsonData['data'] ?? jsonData;
        
        debugPrint('✅ Child added successfully');
        
        return ChildProfile(
          id: childData['_id']?.toString() ?? childData['id']?.toString() ?? '',
          name: childData['name'] ?? name,
          age: childData['age']?.toString() ?? age,
          grade: childData['grade'] ?? grade,
          avatar: childData['avatar'] ?? avatar,
        );
      } else {
        throw Exception('Failed to add child: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error adding child: $e');
      rethrow;
    }
  }

  // Delete child
  static Future<void> deleteChild(String childId) async {
    try {
      debugPrint('🗑️ Deleting child: $childId');
      
      final response = await http.delete(
        Uri.parse('${Config.apiBaseUrl}/child/$childId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete child: ${response.statusCode}');
      }
      
      debugPrint('✅ Child deleted successfully');
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error deleting child: $e');
      rethrow;
    }
  }

  // Update child
  static Future<ChildProfile> updateChild({
    required String childId,
    required String name,
    required String age,
    required String grade,
    required String avatar,
  }) async {
    try {
      debugPrint('✏️ Updating child: $childId');
      
      final response = await http.put(
        Uri.parse('${Config.apiBaseUrl}/child/$childId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'age': int.tryParse(age) ?? 0,
          'grade': grade,
          'avatar': avatar,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final childData = jsonData['data'] ?? jsonData;
        
        debugPrint('✅ Child updated successfully');
        
        return ChildProfile(
          id: childId,
          name: childData['name'] ?? name,
          age: childData['age']?.toString() ?? age,
          grade: childData['grade'] ?? grade,
          avatar: childData['avatar'] ?? avatar,
        );
      } else {
        throw Exception('Failed to update child: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error updating child: $e');
      rethrow;
    }
  }
}