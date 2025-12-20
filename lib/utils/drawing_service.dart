import 'package:flutter/material.dart';
import '../models/pre_writing_shape.dart';

class DrawingService {
  static List<PreWritingShape> getShapes() {
    return [
      PreWritingShape(
        id: 'lines',
        label: 'Lines',
        icon: '—',
        type: ShapeType.lines,
      ),
      PreWritingShape(
        id: 'curves',
        label: 'Curves',
        icon: '∼',
        type: ShapeType.curves,
      ),
      PreWritingShape(
        id: 'zigzag',
        label: 'Zigzag',
        icon: '⩘',
        type: ShapeType.zigzag,
      ),
      PreWritingShape(
        id: 'circles',
        label: 'Circles',
        icon: '○',
        type: ShapeType.circles,
      ),
      PreWritingShape(
        id: 'triangle',
        label: 'Triangle',
        icon: '△',
        type: ShapeType.triangle,
      ),
      PreWritingShape(
        id: 'square',
        label: 'Square',
        icon: '□',
        type: ShapeType.square,
      ),
    ];
  }

  static Paint getDrawingPaint() {
    return Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  static Paint getPatternPaint() {
    return Paint()
      ..color = const Color(0xFFFFD93D)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }
}