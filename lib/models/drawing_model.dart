import 'package:flutter/material.dart';
import '../widgets/drawing_canvas_widget.dart';

class DrawingStroke {
  final String tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  DrawingStroke({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'tool': tool,
      'color': color.toString(),
      'strokeWidth': strokeWidth,
      'points': points
          .map((p) => {'x': p.dx, 'y': p.dy})
          .toList(),
    };
  }
}

class DrawingController {
  String currentTool = 'pen';
  Color currentColor = Colors.orange;
  double currentStrokeWidth = 3.0;
  DrawingCanvasWidgetState? _canvasState;

  void setTool(String tool) {
    currentTool = tool;
  }

  void setColor(Color color) {
    currentColor = color;
  }

  void setStrokeWidth(double width) {
    currentStrokeWidth = width;
  }

  void setCanvasState(DrawingCanvasWidgetState state) {
    _canvasState = state;
  }

  void clearCanvas() {
    _canvasState?.clearCanvas();
  }

  List<Map<String, dynamic>> getDrawingData() {
    return _canvasState?.strokes.map((s) => s.toJson()).toList() ?? [];
  }

  void dispose() {
    _canvasState = null;
  }
}