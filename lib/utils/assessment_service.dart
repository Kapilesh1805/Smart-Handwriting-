import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/assessment_report.dart';

class AssessmentService {
  static const String _baseUrl = 'http://localhost:5000';

  // Fetch latest assessment report for a child from backend
  static Future<AssessmentReport?> fetchAssessmentReport(String childId, {String? childName, int? age, String? grade}) async {
    try {
      debugPrint('📊 Fetching assessment report for child: $childId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/report/child/$childId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final reports = jsonData['data'] as List<dynamic>? ?? [];

        if (reports.isEmpty) {
          debugPrint('⚠️ No reports found for child - returning null');
          return null;
        }

        // Get latest report
        final latestReport = reports.last as Map<String, dynamic>;
        final summary = latestReport['summary'] as Map<String, dynamic>? ?? {};
        final generatedAt = latestReport['generated_at']?.toString() ?? DateTime.now().toString();

        debugPrint('✅ Report loaded with ${reports.length} sessions');

        // Convert backend data to AssessmentReport format
        return AssessmentReport(
          childId: childId,
          childName: childName ?? 'Student',
          childAvatar: 'assets/avatars/student.png',
          age: age ?? 8,
          grade: grade ?? 'Grade 2',
          date: generatedAt.split('T')[0], // Extract date from ISO format
          componentScores: [
            ComponentScore(
              component: 'Pressure Control',
              score: (summary['pressure_score'] as num?)?.toInt() ?? 0,
              maxScore: 100,
              observation: 'Pressure consistency analysis',
            ),
            ComponentScore(
              component: 'Spacing & Alignment',
              score: (summary['spacing_score'] as num?)?.toInt() ?? 0,
              maxScore: 100,
              observation: 'Letter spacing and alignment quality',
            ),
            ComponentScore(
              component: 'Letter Formation',
              score: (summary['formation_score'] as num?)?.toInt() ?? 0,
              maxScore: 100,
              observation: 'Accuracy of letter formation',
            ),
            ComponentScore(
              component: 'Overall Accuracy',
              score: (summary['accuracy_score'] as num?)?.toInt() ?? 0,
              maxScore: 100,
              observation: 'Combined accuracy metric',
            ),
          ],
          visualAnalytics: VisualAnalytics(
            baselineTracking: {
              'Session 1': (summary['pressure_score'] as num?)?.toInt() ?? 0,
              'Session 2': (summary['spacing_score'] as num?)?.toInt() ?? 0,
              'Session 3': (summary['formation_score'] as num?)?.toInt() ?? 0,
            },
            progressChart: {
              'Pressure': (summary['pressure_score'] as num?)?.toDouble() ?? 0,
              'Spacing': (summary['spacing_score'] as num?)?.toDouble() ?? 0,
              'Formation': (summary['formation_score'] as num?)?.toDouble() ?? 0,
              'Accuracy': (summary['accuracy_score'] as num?)?.toDouble() ?? 0,
            },
          ),
          recommendations: TherapistRecommendations(
            improvements: [
              summary['feedback'] ?? 'Continue with handwriting practice',
            ],
            areasToFocus: [
              'Work on pressure consistency',
              'Improve letter spacing',
              'Focus on letter formation accuracy',
            ],
          ),
          nextSessionGoal: 'Improve weak areas with targeted practice',
          overallGrade: _getGrade((summary['overall_score'] as num?)?.toDouble() ?? 0),
          gradePercentage: (summary['overall_score'] as num?)?.toDouble() ?? 0,
        );
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ No reports found (404)');
        return null;
      } else {
        debugPrint('❌ Error fetching report: ${response.statusCode}');
        return null;
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching assessment report: $e');
      return null;
    }
  }

  // Fetch all assessment history for a child
  static Future<List<AssessmentReport>> fetchAssessmentHistory(String childId, {String? childName, int? age, String? grade}) async {
    try {
      debugPrint('📊 Fetching assessment history for child: $childId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/report/child/$childId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final reports = jsonData['data'] as List<dynamic>? ?? [];

        debugPrint('✅ Loaded ${reports.length} reports from history');

        return reports.map((report) {
          final summary = report['summary'] as Map<String, dynamic>? ?? {};
          return AssessmentReport(
            childId: childId,
            childName: childName ?? 'Student',
            childAvatar: 'assets/avatars/student.png',
            age: age ?? 8,
            grade: grade ?? 'Grade 2',
            date: report['generated_at']?.toString().split('T')[0] ?? DateTime.now().toString().split('T')[0],
            componentScores: [
              ComponentScore(
                component: 'Pressure Control',
                score: (summary['pressure_score'] as num?)?.toInt() ?? 0,
                maxScore: 100,
                observation: 'Pressure consistency',
              ),
              ComponentScore(
                component: 'Spacing & Alignment',
                score: (summary['spacing_score'] as num?)?.toInt() ?? 0,
                maxScore: 100,
                observation: 'Letter spacing quality',
              ),
              ComponentScore(
                component: 'Letter Formation',
                score: (summary['formation_score'] as num?)?.toInt() ?? 0,
                maxScore: 100,
                observation: 'Formation accuracy',
              ),
            ],
            visualAnalytics: VisualAnalytics(baselineTracking: {}, progressChart: {}),
            recommendations: TherapistRecommendations(
              improvements: [summary['feedback'] ?? 'Good progress'],
              areasToFocus: [],
            ),
            nextSessionGoal: 'Continue practice',
            overallGrade: _getGrade((summary['overall_score'] as num?)?.toDouble() ?? 0),
            gradePercentage: (summary['overall_score'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
      } else {
        debugPrint('⚠️ No history found');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching history: $e');
      return [];
    }
  }

  // Helper method to convert percentage to grade
  static String _getGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}