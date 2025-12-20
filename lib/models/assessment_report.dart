class AssessmentReport {
  final String childId;
  final String childName;
  final String childAvatar;
  final int age;
  final String grade;
  final String date;
  final List<ComponentScore> componentScores;
  final VisualAnalytics visualAnalytics;
  final TherapistRecommendations recommendations;
  final String nextSessionGoal;
  final String overallGrade;
  final double gradePercentage;

  AssessmentReport({
    required this.childId,
    required this.childName,
    required this.childAvatar,
    required this.age,
    required this.grade,
    required this.date,
    required this.componentScores,
    required this.visualAnalytics,
    required this.recommendations,
    required this.nextSessionGoal,
    required this.overallGrade,
    required this.gradePercentage,
  });

  // TODO: API INTEGRATION - Uncomment when backend is ready
  /*
  factory AssessmentReport.fromJson(Map<String, dynamic> json) {
    return AssessmentReport(
      childId: json['child_id'],
      childName: json['child_name'],
      childAvatar: json['child_avatar'],
      age: json['age'],
      grade: json['grade'],
      date: json['date'],
      componentScores: (json['component_scores'] as List)
          .map((e) => ComponentScore.fromJson(e))
          .toList(),
      visualAnalytics: VisualAnalytics.fromJson(json['visual_analytics']),
      recommendations: TherapistRecommendations.fromJson(json['recommendations']),
      nextSessionGoal: json['next_session_goal'],
      overallGrade: json['overall_grade'],
      gradePercentage: json['grade_percentage'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'child_name': childName,
      'child_avatar': childAvatar,
      'age': age,
      'grade': grade,
      'date': date,
      'component_scores': componentScores.map((e) => e.toJson()).toList(),
      'visual_analytics': visualAnalytics.toJson(),
      'recommendations': recommendations.toJson(),
      'next_session_goal': nextSessionGoal,
      'overall_grade': overallGrade,
      'grade_percentage': gradePercentage,
    };
  }
  */
}

class ComponentScore {
  final String component;
  final int score;
  final int maxScore;
  final String observation;

  ComponentScore({
    required this.component,
    required this.score,
    required this.maxScore,
    required this.observation,
  });

  // TODO: API INTEGRATION
  /*
  factory ComponentScore.fromJson(Map<String, dynamic> json) {
    return ComponentScore(
      component: json['component'],
      score: json['score'],
      maxScore: json['max_score'],
      observation: json['observation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'score': score,
      'max_score': maxScore,
      'observation': observation,
    };
  }
  */
}

class VisualAnalytics {
  final Map<String, int> baselineTracking;
  final Map<String, double> progressChart;

  VisualAnalytics({
    required this.baselineTracking,
    required this.progressChart,
  });

  // TODO: API INTEGRATION
  /*
  factory VisualAnalytics.fromJson(Map<String, dynamic> json) {
    return VisualAnalytics(
      baselineTracking: Map<String, int>.from(json['baseline_tracking']),
      progressChart: Map<String, double>.from(json['progress_chart']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseline_tracking': baselineTracking,
      'progress_chart': progressChart,
    };
  }
  */
}

class TherapistRecommendations {
  final List<String> improvements;
  final List<String> areasToFocus;

  TherapistRecommendations({
    required this.improvements,
    required this.areasToFocus,
  });

  // TODO: API INTEGRATION
  /*
  factory TherapistRecommendations.fromJson(Map<String, dynamic> json) {
    return TherapistRecommendations(
      improvements: List<String>.from(json['improvements']),
      areasToFocus: List<String>.from(json['areas_to_focus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'improvements': improvements,
      'areas_to_focus': areasToFocus,
    };
  }
  */
}