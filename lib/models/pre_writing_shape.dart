import 'package:flutter/material.dart';
class PreWritingShape {
  final String id;
  final String label;
  final String icon;
  final ShapeType type;

  PreWritingShape({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
  });
}

enum ShapeType {
  lines,
  curves,
  zigzag,
  circles,
  triangle,
  square,
}

class DrawingPoint {
  final Offset point;
  final Paint paint;

  DrawingPoint({required this.point, required this.paint});
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final DateTime timestamp;

  DrawingStroke({required this.points, required this.timestamp});
}