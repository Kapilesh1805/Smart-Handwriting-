import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';

class HandwritingAnalysis {
  final String letter;
  final double pressureScore;
  final double spacingScore;
  final double formationScore;
  final double accuracyScore;
  final double overallScore;
  final String feedback;
  final bool modelUsed;

  HandwritingAnalysis({
    required this.letter,
    required this.pressureScore,
    required this.spacingScore,
    required this.formationScore,
    required this.accuracyScore,
    required this.overallScore,
    required this.feedback,
    required this.modelUsed,
  });

  factory HandwritingAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return HandwritingAnalysis(
      letter: json['letter'] ?? 'Unknown',
      pressureScore: (analysis['pressure_score'] ?? 0.0).toDouble(),
      spacingScore: (analysis['spacing_score'] ?? 0.0).toDouble(),
      formationScore: (analysis['formation_score'] ?? 0.0).toDouble(),
      accuracyScore: (analysis['accuracy_score'] ?? 0.0).toDouble(),
      overallScore: (analysis['overall_score'] ?? 0.0).toDouble(),
      feedback: analysis['feedback'] ?? json['feedback'] ?? 'Analysis complete',
      modelUsed: analysis['model_used'] ?? false,
    );
  }
}

class HandwritingService {
  /// Analyze handwriting from canvas drawing
  /// 
  /// [childId] - ID of the child whose handwriting is being analyzed
  /// [letter] - The letter/character being written
  /// [imageBase64] - Base64 encoded image of the drawing (optional)
  /// [strokesData] - Stroke points from the canvas
  /// [pressureData] - Pressure point data from the canvas
  static Future<HandwritingAnalysis> analyzeHandwriting({
    required String childId,
    required String letter,
    String? imageBase64,
    List<dynamic>? strokesData,
    List<dynamic>? pressureData,
  }) async {
    try {
      final token = await Config.getAuthToken();
      
      final url = '${Config.apiBaseUrl}/handwriting/analyze';
      print('🔗 Sending handwriting analysis to: $url');
      print('📝 Data: childId=$childId, letter=$letter');
      print('📐 Strokes: ${strokesData?.length ?? 0}, Pressure points: ${pressureData?.length ?? 0}');

      final requestBody = {
        'child_id': childId,
        'meta': {
          'letter': letter,
        },
        if (imageBase64 != null) 'image_b64': imageBase64,
        if (strokesData != null) 'strokes': strokesData,
        if (pressureData != null) 'pressure_points': pressureData,
      };

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Analysis taking too long.'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Analysis received successfully');
        return HandwritingAnalysis.fromJson(data);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid handwriting data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Analysis failed: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      print('❌ Error analyzing handwriting: $e');
      rethrow;
    }
  }

  /// Get health status of the handwriting analysis backend
  static Future<bool> checkBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.apiBaseUrl}/'))
          .timeout(const Duration(seconds: 3));
      
      print('🔌 Backend health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }
}
