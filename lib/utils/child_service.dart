import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/child_profile.dart';

class ChildService {
  // TODO: API INTEGRATION - Update these when backend is ready
  // static const String baseUrl = 'YOUR_BACKEND_URL/api';
  // static const String apiKey = 'YOUR_API_KEY';

  // Fetch all children
  static Future<List<ChildProfile>> fetchChildren() async {
    try {
      // TODO: API INTEGRATION - Uncomment when backend is ready
      // final response = await http.get(
      //   Uri.parse('$baseUrl/children'),
      //   headers: {
      //     'Authorization': 'Bearer $apiKey',
      //     'Content-Type': 'application/json',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body) as List;
      //   return data.map((json) => ChildProfile.fromJson(json)).toList();
      // } else {
      //   throw Exception('Failed to fetch children: ${response.statusCode}');
      // }

      // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        ChildProfile(
          id: 'child_001',
          name: 'Emma',
          age: '8',
          grade: 'Grade 2',
          avatar: '👧',
          lastAssessment: '17 Sept 2025',
          assessmentStatus: 'Progress',
        ),
        ChildProfile(
          id: 'child_002',
          name: 'Giri',
          age: '10',
          grade: 'UKG',
          avatar: '😊',
          lastAssessment: '15 Sept 2025',
          assessmentStatus: 'Progress',
        ),
        ChildProfile(
          id: 'child_003',
          name: 'Rohan',
          age: '7',
          grade: 'Grade 1',
          avatar: '👦',
          lastAssessment: '18 Sept 2025',
          assessmentStatus: 'Needs Improvement',
        ),
        ChildProfile(
          id: 'child_004',
          name: 'Priya',
          age: '9',
          grade: 'Grade 3',
          avatar: '🧒',
          lastAssessment: '16 Sept 2025',
          assessmentStatus: 'Progress',
        ),
      ];
      // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
    } catch (e) {
      throw Exception('Error fetching children: $e');
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
      // TODO: API INTEGRATION - Uncomment when backend is ready
      // final response = await http.post(
      //   Uri.parse('$baseUrl/children'),
      //   headers: {
      //     'Authorization': 'Bearer $apiKey',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode({
      //     'name': name,
      //     'age': int.parse(age),
      //     'grade': grade,
      //     'avatar': avatar,
      //     'created_at': DateTime.now().toIso8601String(),
      //   }),
      // );
      //
      // if (response.statusCode == 201) {
      //   final data = json.decode(response.body);
      //   return ChildProfile.fromJson(data);
      // } else {
      //   throw Exception('Failed to add child: ${response.statusCode}');
      // }

      // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
      await Future.delayed(const Duration(milliseconds: 300));
      final child = ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: age,
        grade: grade,
        avatar: avatar,
        lastAssessment: null,
        assessmentStatus: null,
      );
      return child;
      // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
    } catch (e) {
      throw Exception('Error adding child: $e');
    }
  }

  // Delete child
  static Future<void> deleteChild(String childId) async {
    try {
      // TODO: API INTEGRATION - Uncomment when backend is ready
      // final response = await http.delete(
      //   Uri.parse('$baseUrl/children/$childId'),
      //   headers: {
      //     'Authorization': 'Bearer $apiKey',
      //     'Content-Type': 'application/json',
      //   },
      // );
      //
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to delete child: ${response.statusCode}');
      // }

      // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
      await Future.delayed(const Duration(milliseconds: 300));
      // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
    } catch (e) {
      throw Exception('Error deleting child: $e');
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
      // TODO: API INTEGRATION - Uncomment when backend is ready
      // final response = await http.put(
      //   Uri.parse('$baseUrl/children/$childId'),
      //   headers: {
      //     'Authorization': 'Bearer $apiKey',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode({
      //     'name': name,
      //     'age': int.parse(age),
      //     'grade': grade,
      //     'avatar': avatar,
      //   }),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return ChildProfile.fromJson(data);
      // } else {
      //   throw Exception('Failed to update child: ${response.statusCode}');
      // }

      // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
      await Future.delayed(const Duration(milliseconds: 300));
      final child = ChildProfile(
        id: childId,
        name: name,
        age: age,
        grade: grade,
        avatar: avatar,
      );
      return child;
      // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
    } catch (e) {
      throw Exception('Error updating child: $e');
    }
  }
}