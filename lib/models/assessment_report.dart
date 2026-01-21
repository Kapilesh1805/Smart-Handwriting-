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


}

class VisualAnalytics {
  final Map<String, int> baselineTracking;
  final Map<String, double> progressChart;

  VisualAnalytics({
    required this.baselineTracking,
    required this.progressChart,
  });

}

class TherapistRecommendations {
  final List<String> improvements;
  final List<String> areasToFocus;

  TherapistRecommendations({
    required this.improvements,
    required this.areasToFocus,
  });
}