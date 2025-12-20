class ChildProfile {
  final String id;
  final String name;
  final String age;
  final String grade;
  final String avatar;
  final String? lastAssessment;
  final String? assessmentStatus;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.avatar,
    this.lastAssessment,
    this.assessmentStatus,
  });

  // API INTEGRATION - Use this factory method
  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age']?.toString() ?? '',
      grade: json['grade'] ?? '',
      avatar: json['avatar'] ?? '👦',
      lastAssessment: json['last_assessment'],
      assessmentStatus: json['assessment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'grade': grade,
      'avatar': avatar,
      'last_assessment': lastAssessment,
      'assessment_status': assessmentStatus,
    };
  }
}