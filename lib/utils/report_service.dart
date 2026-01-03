import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import 'api_config.dart';

class ReportService {
  static const String _apiUrl = 'http://localhost:5000';

  /// Get all reports for a specific child
  static Future<ChildReport?> getChildReport(String childId) async {
    try {
      debugPrint('📊 Fetching report for child: $childId');

      final response = await http.get(
        Uri.parse('$_apiUrl/report/child/$childId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Report response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final reports = jsonData['data'] as List<dynamic>? ?? [];

        if (reports.isEmpty) {
          debugPrint('⚠️ No reports found for child');
          return null;
        }

        // Get child profile for additional info
        final prefs = await SharedPreferences.getInstance();
        final childName = prefs.getString('child_name_$childId') ?? 'Unknown';
        final childAge = prefs.getInt('child_age_$childId');
        final childGrade = prefs.getString('child_grade_$childId');

        // Aggregate all analysis scores from reports
        final allScores = <AnalysisScore>[];
        for (final report in reports) {
          final summary = report['summary'] as Map<String, dynamic>? ?? {};
          if (summary.isNotEmpty) {
            allScores.add(AnalysisScore.fromJson({
              ...summary,
              'timestamp': report['generated_at'] ?? DateTime.now().toIso8601String(),
            }));
          }
        }

        final childReport = ChildReport(
          childId: childId,
          childName: childName,
          age: childAge,
          grade: childGrade,
          analysisScores: allScores,
          generatedAt: DateTime.now(),
        );

        debugPrint(
          '✅ Report loaded: ${allScores.length} scores, Average: ${childReport.overallAverage.toStringAsFixed(2)}%',
        );

        return childReport;
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ No reports found (404)');
        return null;
      } else {
        debugPrint('❌ Error fetching report: ${response.statusCode}');
        throw Exception('Failed to fetch report: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error fetching report: $e');
      throw Exception('Network error: $e');
    } catch (e) {
      debugPrint('❌ Error fetching report: $e');
      return null;
    }
  }

  /// Get all children for selection
  static Future<List<Map<String, dynamic>>> getAllChildren() async {
    try {
      debugPrint('📊 Fetching all children...');

      // Get from SharedPreferences (cached children list)
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = prefs.getString('children_list');

      if (childrenJson != null) {
        final children = jsonDecode(childrenJson) as List<dynamic>;
        debugPrint('✅ Loaded ${children.length} children from cache');
        return children.cast<Map<String, dynamic>>();
      }

      debugPrint('⚠️ No children cached');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching children: $e');
      return [];
    }
  }

  /// Export report as PDF
  static Future<bool> exportReportAsPdf(String childId) async {
    try {
      debugPrint('📄 Exporting report as PDF for child: $childId');

      final response = await http.get(
        Uri.parse('$_apiUrl/report/export/$childId'),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📄 Export response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ PDF exported successfully');
        return true;
      } else {
        debugPrint('❌ Export failed: ${response.statusCode}');
        return false;
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error exporting PDF: $e');
      return false;
    } catch (e) {
      debugPrint('❌ Error exporting PDF: $e');
      return false;
    }
  }

  /// Email report to parent
  static Future<bool> emailReportToParent(
    String childId,
    String parentEmail,
  ) async {
    try {
      debugPrint(
        '📧 Emailing report for child $childId to $parentEmail',
      );

      final response = await http.post(
        Uri.parse('$_apiUrl/report/email/$childId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': parentEmail}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📧 Email response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Report emailed successfully');
        return true;
      } else {
        debugPrint('❌ Email failed: ${response.statusCode}');
        return false;
      }
    } on http.ClientException catch (e) {
      debugPrint('🔗 Network error sending email: $e');
      return false;
    } catch (e) {
      debugPrint('❌ Error emailing report: $e');
      return false;
    }
  }

  /// Get progress trend (scores over time)
  static List<Map<String, dynamic>> getProgressTrend(
    ChildReport report, {
    int limit = 10,
  }) {
    final sorted = List<AnalysisScore>.from(report.analysisScores)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return sorted.take(limit).map((score) {
      return {
        'date': score.timestamp,
        'overall': score.overallScore,
        'pressure': score.pressureScore,
        'spacing': score.spacingScore,
        'formation': score.formationScore,
      };
    }).toList();
  }

  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary(ChildReport report) {
    return {
      'total_sessions': report.analysisScores.length,
      'overall_average': report.overallAverage,
      'pressure_average': report.averagePressure,
      'spacing_average': report.averageSpacing,
      'formation_average': report.averageFormation,
      'letters_practiced': report.practizedLetters.length,
      'completion_percentage': report.completionPercentage,
      'top_letters': report.getTopLetters(),
      'letters_needing_help': report.getLettersNeedingHelp(),
    };
  }
}
