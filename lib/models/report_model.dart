import 'dart:io';

class AnalysisScore {
  /// Convert percentage score (0-100) to 0-2 scale
  /// 0-39 = 0, 40-69 = 1, 70-100 = 2
  static int convertPercentageToScale(double percentage) {
    if (percentage >= 70) return 2;
    if (percentage >= 40) return 1;
    return 0;
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
  final double? pressureScore;
  final double? spacingScore;
  // formationScore can be String (alphabet) or double (number mode)
  final dynamic formationScore;
  final double accuracyScore;
  final double overallScore;
  final String feedback;
  final String? letter;
  final DateTime timestamp;

  AnalysisScore({
    required this.pressureScore,
    required this.spacingScore,
    this.formationScore,
    required this.accuracyScore,
    required this.overallScore,
    required this.feedback,
    this.letter,
    required this.timestamp,
  });

  factory AnalysisScore.fromJson(Map<String, dynamic> json) {
    // SAFE numeric parsing - keep as percentages, nullable
    final pressureScore = (json['pressure_score'] as num?)?.toDouble();
    final spacingScore = (json['spacing_score'] as num?)?.toDouble();
    final accuracyScore = (json['accuracy_score'] as num?)?.toDouble() ?? 0.0;
    final overallScore = (json['overall_score'] as num?)?.toDouble() ?? 0.0;
    
    // formationScore can be String or double
    dynamic formationScore;
    final rawFormation = json['formation_score'];
    if (rawFormation is String) {
      formationScore = rawFormation;
    } else if (rawFormation is num) {
      formationScore = rawFormation.toDouble();
    } else if (rawFormation != null) {
      formationScore = (rawFormation as num?)?.toDouble();
    }
    
    return AnalysisScore(
      pressureScore: pressureScore,
      spacingScore: spacingScore,
      formationScore: formationScore,
      accuracyScore: accuracyScore,
      overallScore: overallScore,
      feedback: json['feedback'] as String? ?? '',
      letter: json['letter'] as String?,
      timestamp: json['timestamp'] != null
          ? parseBackendTimestamp(json['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChildReport {
  final String childId;
  final String childName;
  final int? age;
  final String? grade;
  final List<AnalysisScore> analysisScores;
  final DateTime generatedAt;

  ChildReport({
    required this.childId,
    required this.childName,
    this.age,
    this.grade,
    required this.analysisScores,
    required this.generatedAt,
  });

  // Calculate averages - convert to 0-2 scale, default 0 if no data
  int get averagePressure {
    final validScores = analysisScores.where((s) => s.pressureScore != null).toList();
    if (validScores.isEmpty) return 0;
    final avg = validScores.fold<double>(0.0, (sum, s) => sum + s.pressureScore!) / validScores.length;
    return AnalysisScore.convertPercentageToScale(avg);
  }

  int get averageSpacing {
    final validScores = analysisScores.where((s) => s.spacingScore != null).toList();
    if (validScores.isEmpty) return 0;
    final avg = validScores.fold<double>(0.0, (sum, s) => sum + s.spacingScore!) / validScores.length;
    return AnalysisScore.convertPercentageToScale(avg);
  }

  int get averageAccuracy {
    if (analysisScores.isEmpty) return 0;
    final avg = analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.accuracyScore,
        ) /
        analysisScores.length;
    return AnalysisScore.convertPercentageToScale(avg);
  }

  // Presence-based ranks for Pressure and Accuracy
  int get pressureRank {
    return analysisScores.where((s) => s.pressureScore?.isFinite == true).isNotEmpty ? 2 : 0;
  }

  int get accuracyRank {
    return analysisScores.any((s) => s.accuracyScore != null && !s.accuracyScore.isNaN) ? 2 : 0;
  }

  double get averageFormation {
    if (analysisScores.isEmpty) return 0.0;
    // Map formation labels to numeric values for averaging (0..100)
    const Map<String, double> formationMap = {
      'Poor': 30.0,
      'Average': 60.0,
      'Good': 90.0,
    };

    double mapLabel(dynamic label) {
      if (label == null) return 0.0;
      // If already numeric, convert to double
      if (label is num) return label.toDouble();
      // If string, check map or try parsing
      if (label is String) {
        if (formationMap.containsKey(label)) return formationMap[label]!;
        final parsed = double.tryParse(label);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    final total = analysisScores.fold<double>(
      0.0,
      (sum, score) => sum + mapLabel(score.formationScore),
    );

    return total / analysisScores.length;
  }

  double get overallAverage {
    if (analysisScores.isEmpty) return 0.0;
    return analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.overallScore,
        ) /
        analysisScores.length;
  }

  // Get unique letters practiced
  Set<String> get practizedLetters {
    return analysisScores
        .where((score) => score.letter != null && score.letter!.isNotEmpty)
        .map((score) => score.letter!)
        .toSet();
  }

  // Get completion percentage (letters practiced / 26 letters)
  double get completionPercentage {
    return (practizedLetters.length / 26) * 100;
  }

  // Get top performing letters (by accuracy)
  List<String> getTopLetters({int limit = 5}) {
    final letterScores = <String, double>{};

    for (final score in analysisScores) {
      if (score.letter != null && score.letter!.isNotEmpty) {
        final letter = score.letter!.toUpperCase();
        if (letterScores.containsKey(letter)) {
          letterScores[letter] = (letterScores[letter]! + score.overallScore) / 2;
        } else {
          letterScores[letter] = score.overallScore;
        }
      }
    }

    final sorted = letterScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  // Get letters needing improvement (below 70%)
  List<String> getLettersNeedingHelp({double threshold = 70.0}) {
    final letterScores = <String, double>{};

    for (final score in analysisScores) {
      if (score.letter != null && score.letter!.isNotEmpty) {
        final letter = score.letter!.toUpperCase();
        if (letterScores.containsKey(letter)) {
          letterScores[letter] = (letterScores[letter]! + score.overallScore) / 2;
        } else {
          letterScores[letter] = score.overallScore;
        }
      }
    }

    return letterScores.entries
        .where((e) => e.value < threshold)
        .map((e) => e.key)
        .toList();
  }

  factory ChildReport.fromJson(Map<String, dynamic> json) {
    final scoresList = (json['analysis_scores'] as List<dynamic>?)
            ?.map((s) => AnalysisScore.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return ChildReport(
      childId: json['child_id'] as String? ?? '',
      childName: json['child_name'] as String? ?? 'Unknown',
      age: json['age'] as int?,
      grade: json['grade'] as String?,
      analysisScores: scoresList,
      generatedAt: json['generated_at'] != null
          ? AnalysisScore.parseBackendTimestamp(json['generated_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'child_name': childName,
        'age': age,
        'grade': grade,
        'analysis_scores': analysisScores.map((s) => s).toList(),
        'generated_at': generatedAt.toIso8601String(),
      };
}
