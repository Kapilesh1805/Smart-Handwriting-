class AnalysisScore {
  final double pressureScore;
  final double spacingScore;
  final double formationScore;
  final double accuracyScore;
  final double overallScore;
  final String feedback;
  final String? letter;
  final DateTime timestamp;

  AnalysisScore({
    required this.pressureScore,
    required this.spacingScore,
    required this.formationScore,
    required this.accuracyScore,
    required this.overallScore,
    required this.feedback,
    this.letter,
    required this.timestamp,
  });

  factory AnalysisScore.fromJson(Map<String, dynamic> json) {
    return AnalysisScore(
      pressureScore: (json['pressure_score'] as num?)?.toDouble() ?? 0.0,
      spacingScore: (json['spacing_score'] as num?)?.toDouble() ?? 0.0,
      formationScore: (json['formation_score'] as num?)?.toDouble() ?? 0.0,
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      feedback: json['feedback'] as String? ?? '',
      letter: json['letter'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
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

  // Calculate averages
  double get averagePressure {
    if (analysisScores.isEmpty) return 0.0;
    return analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.pressureScore,
        ) /
        analysisScores.length;
  }

  double get averageSpacing {
    if (analysisScores.isEmpty) return 0.0;
    return analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.spacingScore,
        ) /
        analysisScores.length;
  }

  double get averageFormation {
    if (analysisScores.isEmpty) return 0.0;
    return analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.formationScore,
        ) /
        analysisScores.length;
  }

  double get averageAccuracy {
    if (analysisScores.isEmpty) return 0.0;
    return analysisScores.fold<double>(
          0.0,
          (sum, score) => sum + score.accuracyScore,
        ) /
        analysisScores.length;
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
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
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
