import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/api_config.dart';

class HandwritingAnalysis {
  final String letter;
  final double pressureScore;
  final double spacingScore;
  // formationScore can be:
  // - Alphabet mode: semantic label (String) "Poor", "Average", "Good"
  // - Number mode: numeric value (double) 0.0-100.0
  // Store as dynamic and convert in UI as needed
  final dynamic formationScore;
  final double accuracyScore;
  final double overallScore;
  final double? visualScore;
  final String? pressureSource;
  final String? predictedLetter;
  // Match type indicates character validation result: 'Exact', 'VisualMatch', 'Incorrect'
  final String? matchType;
  final bool isMatch;
  // ✅ NEW: Single source of truth for correctness
  final bool? isCorrect;
  // ✅ NEW: Recognized vs expected characters for visual equivalence
  final String? recognizedChar;
  final String? expectedChar;
  final String feedback;
  final bool modelUsed;
  final List<dynamic>? rawPressurePoints;
  // Stable frontend-facing values parsed from backend top-level keys
  final double confidence;
  final double formation;
  final double? pressure;
  // ✅ NEW: Evaluation mode that was used (alphabet or number)
  final String? evaluationMode;
  // CLIP similarity map: digit -> similarity score (-1 to 1)
  final Map<String, double>? clipSimilarityMap;

  HandwritingAnalysis({
    required this.letter,
    required this.pressureScore,
    required this.spacingScore,
    this.formationScore,
    required this.accuracyScore,
    required this.overallScore,
    // Expose stable top-level values for frontend use
    required this.confidence,
    required this.formation,
    this.pressure,
    required this.feedback,
    required this.modelUsed,
    this.visualScore,
    this.pressureSource,
    this.predictedLetter,
    this.matchType,
    this.isMatch = false,
    this.isCorrect,
    this.recognizedChar,
    this.expectedChar,
    this.rawPressurePoints,
    this.evaluationMode,
    this.clipSimilarityMap,
  });

  factory HandwritingAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    final rawPoints = json['pressure_points_received'] ?? analysis['pressure_points'] ?? json['pressure_points'];
    
    // ✅ FIX: SAFE isCorrect parsing - Check both nested and top-level locations
    bool? isCorrectValue = analysis['is_correct'] as bool? ?? json['is_correct'] as bool?;
    debugPrint('[HandwritingAnalysis] isCorrect=$isCorrectValue (nested=${analysis['is_correct']}, toplevel=${json['is_correct']})');
    
    // ✅ NEW: Parse from stable response contract (confidence, formation, pressure)
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final formation = (json['formation'] as num?)?.toDouble() ?? confidence;  // fallback to confidence
    final pressure = json['pressure'] as num?;  // Can be null
    
    // SAFE numeric parsing for legacy nested fields
    final pressureScore = (analysis['pressure_score'] as num?)?.toDouble() ?? (pressure?.toDouble() ?? 0.0);
    final spacingScore = (analysis['spacing_score'] as num?)?.toDouble() ?? 0.0;
    final accuracyScore = (analysis['accuracy_score'] as num?)?.toDouble() ?? confidence;
    final overallScore = (analysis['overall_score'] as num?)?.toDouble() ?? confidence;
    final visualScore = (analysis['visual_score'] as num?)?.toDouble();
    
    // formationScore can be String (alphabet mode) or double (number mode)
    dynamic formationScore;
    final rawFormation = analysis['formation_score'] ?? formation;
    if (rawFormation is String) {
      formationScore = rawFormation; // Keep semantic label
    } else if (rawFormation is num) {
      formationScore = rawFormation.toDouble(); // Convert to numeric
    } else if (rawFormation != null) {
      // Try parsing as number
      formationScore = (rawFormation as num?)?.toDouble();
    }
    // Otherwise null
    
    // SAFE clip_similarity map parsing
    Map<String, double>? clipSimilarityMap;
    final rawClipSim = analysis['clip_similarity'];
    if (rawClipSim is Map<String, dynamic>) {
      clipSimilarityMap = rawClipSim.map(
        (k, v) => MapEntry(k, (v as num).toDouble())
      );
    }
    
    return HandwritingAnalysis(
      letter: json['letter'] ?? 'Unknown',
      pressureScore: pressureScore,
      spacingScore: spacingScore,
      formationScore: formationScore,
      accuracyScore: accuracyScore,
      overallScore: overallScore,
      // Expose stable top-level values for frontend use
      confidence: confidence,
      formation: formation,
      pressure: pressure?.toDouble(),
      visualScore: visualScore,
      pressureSource: analysis['pressure_source'] ?? json['pressure_source'],
      predictedLetter: analysis['predicted_letter'] ?? json['predicted_letter'],
      matchType: analysis['match_type'] as String?,
      isMatch: analysis['is_match'] as bool? ?? false,
      // ✅ FIX: Use parsed isCorrectValue (from either nested or top-level)
      isCorrect: isCorrectValue,
      // ✅ NEW: Extract character recognition details
      recognizedChar: analysis['recognized_char'] as String?,
      expectedChar: analysis['expected_char'] as String?,
      feedback: analysis['feedback'] ?? json['feedback'] ?? 'Analysis complete',
      modelUsed: analysis['model_used'] ?? false,
      rawPressurePoints: rawPoints is List ? rawPoints : (rawPoints != null ? [rawPoints] : null),
      // ✅ NEW: Extract evaluation mode from response
      evaluationMode: json['evaluation_mode'] as String? ?? json['mode'] as String? ?? 'alphabet',
      clipSimilarityMap: clipSimilarityMap,
    );
  }
}

class HandwritingService {
  /// Analyze handwriting from canvas drawing
  /// 
  /// [childId] - ID of the child whose handwriting is being analyzed
  /// [letter] - The letter/character being written
  /// [evaluationMode] - "alphabet" or "number" (determines which pipeline to use)
  /// [imageBase64] - Base64 encoded image of the drawing (optional)
  /// [strokesData] - Stroke points from the canvas
  /// [pressureData] - Pressure point data from the canvas
  static Future<HandwritingAnalysis> analyzeHandwriting({
    required String childId,
    required String letter,
    String? evaluationMode,
    String? imageBase64,
    List<dynamic>? strokesData,
    List<dynamic>? pressureData,
  }) async {
    try {
      final token = await Config.getAuthToken();
      
      // ✅ FIX: Route to correct endpoint based on evaluation mode
      final mode = evaluationMode ?? 'alphabet';
      final endpoint = mode == 'number' ? '/handwriting/analyze-number' : '/handwriting/analyze';
      final url = '${Config.apiBaseUrl}$endpoint';
      
      debugPrint('🔗 Sending to: $url (mode=$mode)');
      debugPrint('📝 Data: childId=$childId, letter=$letter, evaluationMode=$mode');
      debugPrint('📐 Strokes: ${strokesData?.length ?? 0}, Pressure points: ${pressureData?.length ?? 0}');

      final requestBody = {
        'child_id': childId,
        'meta': {
          'letter': letter,
        },
        // ✅ NEW: Include evaluation mode (default to alphabet if not specified)
        'evaluation_mode': mode,
        // request CLIP as primary visual analyzer
        'prefer_clip': true,
        if (imageBase64 != null) 'image_b64': imageBase64,
        if (strokesData != null) 'strokes': strokesData,
        if (pressureData != null) 'pressure_points': pressureData,
      };

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // First request: 12 second timeout, handle 202 warm-up
      debugPrint('[ANALYZE] First request (timeout: 12s)...');
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Request timeout. Analysis taking too long.'),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      // ✅ NEW: Handle 202 warm-up response
      if (response.statusCode == 202) {
        final data = json.decode(response.body);
        if (data['status'] == 'warming_up') {
          debugPrint('[ANALYZE] ⏳ CLIP warming up, waiting 700ms then retrying...');
          await Future.delayed(const Duration(milliseconds: 700));
          
          debugPrint('[ANALYZE] Retry request (timeout: 12s)...');
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          ).timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw Exception('Request timeout after warm-up. Analysis taking too long.'),
          );
          
          debugPrint('📡 Retry response status: ${response.statusCode}');
          debugPrint('📄 Retry response body: ${response.body}');
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Analysis received successfully');
        // If backend echoes pressure points, log them for verification
        if (data.containsKey('pressure_points_received')) {
          debugPrint('🧾 Backend echoed pressure points: ${data['pressure_points_received']}');
        }
          // adapt to backend keys: pressure_score or pressure_consistency
        if (data is Map<String, dynamic>) {
          final analysis = data['analysis'] as Map<String, dynamic>? ?? {};
          // normalize pressure key names
          if (analysis['pressure_consistency'] != null && analysis['pressure_score'] == null) {
            analysis['pressure_score'] = analysis['pressure_consistency'];
          }
        }
        return HandwritingAnalysis.fromJson(data);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid handwriting data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Backend endpoint not found. Check server configuration.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error (${response.statusCode}). Check backend logs.');
      } else {
        throw Exception('Analysis failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('🌐 Network error: $e');
      // Only show "No internet" for actual network/socket errors
      throw Exception('Cannot reach backend server. Check your connection and server status.');
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout error: $e');
      throw Exception('Analysis request timed out. Server may be busy or unreachable.');
    } catch (e) {
      debugPrint('❌ Error analyzing handwriting: $e');
      rethrow;
    }
  }

  /// Get health status of the handwriting analysis backend
  static Future<bool> checkBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.apiBaseUrl}/'))
          .timeout(const Duration(seconds: 3));
      
      debugPrint('🔌 Backend health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }
}
