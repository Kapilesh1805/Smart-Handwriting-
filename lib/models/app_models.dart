import 'package:flutter/material.dart' ;
class AppointmentItem {
  final String title;
  final String childName;
  final String timeLabel;
  final String? avatarAsset;
  final bool highlighted;
  const AppointmentItem({
    required this.title,
    required this.childName,
    required this.timeLabel,
    this.avatarAsset,
    this.highlighted = false,
  });
}

class UserProfile {
  final String name;
  final String occupation;
  const UserProfile({required this.name, required this.occupation});
}

// TODO: API INTEGRATION - If backend sends more fields, replace with this:
// class UserProfile {
//   final String id;
//   final String name;
//   final String occupation;
//   final String? email;
//   final String? avatarUrl;
//   final String? phone;
//
//   const UserProfile({
//     required this.id,
//     required this.name,
//     required this.occupation,
//     this.email,
//     this.avatarUrl,
//     this.phone,
//   });
//
//   factory UserProfile.fromJson(Map<String, dynamic> json) {
//     return UserProfile(
//       id: json['id'].toString(),
//       name: json['name'] ?? 'User',
//       occupation: json['occupation'] ?? 'Therapist',
//       email: json['email'],
//       avatarUrl: json['avatar_url'],
//       phone: json['phone'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'occupation': occupation,
//       'email': email,
//       'avatar_url': avatarUrl,
//       'phone': phone,
//     };
//   }
// }

class AppointmentSlotData {
  final String label;
  final Color color;
  const AppointmentSlotData(this.label, this.color);
}

class DrawingPoint {
  final Offset? points;
  final Paint paint;

  DrawingPoint({this.points, required this.paint});
}