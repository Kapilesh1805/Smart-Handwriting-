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