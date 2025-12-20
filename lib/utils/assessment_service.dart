import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/assessment_report.dart';

class AssessmentService {
  // TODO: API INTEGRATION - Update these when backend is ready
  // static const String baseUrl = 'YOUR_BACKEND_URL/api';
  // static const String apiKey = 'YOUR_API_KEY';

  // Fetch latest assessment report for a child
  static Future<AssessmentReport?> fetchAssessmentReport(String childId) async {
    try {
      // TODO: API INTEGRATION - Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$childId/latest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AssessmentReport.fromJson(data);
      }
      return null;
      */

      // REMOVE THIS BLOCK AFTER API INTEGRATION - Mock data for testing
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockAssessmentReport(childId);
    } catch (e) {
      print('Error fetching assessment report: $e');
      return null;
    }
  }

  // Fetch all assessment history for a child
  static Future<List<AssessmentReport>> fetchAssessmentHistory(String childId) async {
    try {
      // TODO: API INTEGRATION - Uncomment when backend is ready
      /*
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$childId/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AssessmentReport.fromJson(json)).toList();
      }
      return [];
      */

      // REMOVE THIS BLOCK AFTER API INTEGRATION
      await Future.delayed(const Duration(milliseconds: 500));
      return [_getMockAssessmentReport(childId)];
    } catch (e) {
      print('Error fetching assessment history: $e');
      return [];
    }
  }

  // REMOVE THIS METHOD AFTER API INTEGRATION - Mock data generator
  static AssessmentReport _getMockAssessmentReport(String childId) {
    return AssessmentReport(
      childId: childId,
      childName: 'Emily',
      childAvatar: 'assets/avatars/girl.png',
      age: 7,
      grade: 'Three',
      date: 'Nov 16, 2024',
      componentScores: [
        ComponentScore(
          component: 'Shape Formation',
          score: 3,
          maxScore: 5,
          observation: 'Letter shapes mostly correct',
        ),
        ComponentScore(
          component: 'Letter Formation',
          score: 3,
          maxScore: 5,
          observation: 'Consistent letter structure',
        ),
        ComponentScore(
          component: 'Size/Font Control',
          score: 2,
          maxScore: 5,
          observation: 'Needs uniform size practice',
        ),
        ComponentScore(
          component: 'Sentence Writing',
          score: 3,
          maxScore: 5,
          observation: 'Some control of signs & spaces',
        ),
        ComponentScore(
          component: 'Spacing',
          score: 2,
          maxScore: 5,
          observation: 'Needs spacing practice',
        ),
        ComponentScore(
          component: 'Tool Consistency',
          score: 3,
          maxScore: 5,
          observation: 'Median marks visible',
        ),
        ComponentScore(
          component: 'Legibility',
          score: 13,
          maxScore: 18,
          observation: '',
        ),
      ],
      visualAnalytics: VisualAnalytics(
        baselineTracking: {
          'Week 1': 12,
          'Week 2': 15,
          'Week 3': 18,
          'Week 4': 20,
        },
        progressChart: {
          'Session 1': 45.0,
          'Session 2': 52.0,
          'Session 3': 58.0,
          'Session 4': 65.0,
        },
      ),
      recommendations: TherapistRecommendations(
        improvements: [
          'Letter spacing has improved significantly',
          'Tool grip has shown consistent progress',
          'Focus on writing within (short sentences)',
        ],
        areasToFocus: [
          'Use varied grips to regulate pencil pressure',
          'Work on consistent letter size',
        ],
      ),
      nextSessionGoal: 'Improve number formation accuracy',
      overallGrade: 'B',
      gradePercentage: 72.2,
    );
  }
}