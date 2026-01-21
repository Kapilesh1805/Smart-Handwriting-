import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import '../config/api_config.dart';

class ReportService {
  // Use Config.apiBaseUrl instead of hardcoding

  /// Convert percentage score (0-100) to 0-2 scale
  /// 0-33% = 0, 34-66% = 1, 67-100% = 2
  static int convertPercentageToScale(double percentage) {
    if (percentage < 34) return 0;
    if (percentage < 67) return 1;
    return 2;
  }

  /// Safe timestamp parser with RFC 1123 fallback
  static DateTime parseBackendTimestamp(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    try {
      // Try ISO 8601 first
      return DateTime.parse(value);
    } catch (_) {
      try {
        // Fallback for RFC 1123 / HTTP-date
        return HttpDate.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }

  /// Get all reports for a specific child with proper score parsing and conversion
  static Future<ChildReport?> getChildReport(String childId, {String? childName, int? childAge}) async {
    try {
      debugPrint('📊 Fetching report for child: $childId');

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/report/child/$childId'),
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

        // Get child profile for additional info from parameters or SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final finalChildName = childName ?? prefs.getString('child_name_$childId') ?? 'Unknown';
        final finalChildAge = childAge ?? prefs.getInt('child_age_$childId');
        final childGrade = prefs.getString('child_grade_$childId');

        // Aggregate all analysis scores from reports with improved parsing
        final allScores = <AnalysisScore>[];
        for (final report in reports) {
          final analysis = report['analysis'] as Map<String, dynamic>? ?? {};
          
          // Merge top-level fields with analysis
          final combinedData = {
            ...report,  // includes accuracy, etc.
            ...analysis,  // includes pressure_score, formation_score
            'accuracy_score': report['accuracy'],  // map accuracy to accuracy_score
            'overall_score': report['accuracy'],  // use accuracy as overall for now
            'letter': report['character'],  // map character to letter
            'feedback': 'Analysis completed',  // default feedback
          };
          
          if (combinedData.isNotEmpty) {
            // Parse timestamp safely - handle both ISO 8601 and HTTP date formats
            DateTime parsedTime = DateTime.now();
            final timeStr = report['generated_at'] ?? report['created_at'];
            if (timeStr != null) {
              parsedTime = parseBackendTimestamp(timeStr as String);
            }

            allScores.add(AnalysisScore.fromJson({
              ...combinedData,
              'timestamp': parsedTime.toIso8601String(),
            }));
          }
        }

        final childReport = ChildReport(
          childId: childId,
          childName: finalChildName,
          age: finalChildAge,
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

  /// Export report as PDF
  static Future<bool> exportReportAsPdf(String childId) async {
    try {
      debugPrint('📄 Exporting report as PDF for child: $childId');

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/report/export/$childId'),
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
        Uri.parse('${Config.apiBaseUrl}/report/email/$childId'),
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
