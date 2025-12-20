import 'package:flutter/material.dart';
import '../models/drawing_model.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final DrawingController controller;
  final Color backgroundColor;

  const DrawingCanvasWidget({
    super.key,
    required this.controller,
    required this.backgroundColor,
  });

  @override
  State<DrawingCanvasWidget> createState() => DrawingCanvasWidgetState();
}

class DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  List<DrawingStroke> strokes = [];
  DrawingStroke? currentStroke;

  void addStroke(DrawingStroke stroke) {
    setState(() {
      strokes.add(stroke);
    });
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.setCanvasState(this);
    
    return GestureDetector(
      onPanStart: (details) {
        currentStroke = DrawingStroke(
          tool: widget.controller.currentTool,
          color: widget.controller.currentColor,
          strokeWidth: widget.controller.currentStrokeWidth,
          points: [details.localPosition],
        );
      },
      onPanUpdate: (details) {
        setState(() {
          currentStroke?.points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        if (currentStroke != null && currentStroke!.points.isNotEmpty) {
          addStroke(currentStroke!);
          currentStroke = null;
        }
      },
      child: CustomPaint(
        painter: DrawingPainter(
          strokes: strokes,
          currentStroke: currentStroke,
        ),
        child: Container(
          color: widget.backgroundColor,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (var stroke in strokes) {
      _drawStroke(canvas, stroke, size);
    }

    // Draw current stroke being drawn
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, size);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, Size size) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.tool == 'eraser') {
      paint.color = const Color(0xFFFFF8E7); // Background color - erase by drawing background color
      paint.strokeWidth = stroke.strokeWidth * 3;
      paint.strokeCap = StrokeCap.round;
      paint.strokeJoin = StrokeJoin.round;
    }

    if (stroke.points.isEmpty) return;

    switch (stroke.tool) {
      case 'pen':
      case 'eraser':
        _drawPen(canvas, paint, stroke.points);
        break;
      case 'line':
        _drawLine(canvas, paint, stroke.points);
        break;
      case 'curve':
        _drawCurve(canvas, paint, stroke.points);
        break;
      case 'circle':
        _drawCircle(canvas, paint, stroke.points);
        break;
      case 'triangle':
        _drawTriangle(canvas, paint, stroke.points);
        break;
      default:
        _drawPen(canvas, paint, stroke.points);
    }
  }

  void _drawPen(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.isEmpty) return;
    
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  void _drawLine(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    
    final paint2 = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawLine(points.first, points.last, paint2);
  }

  void _drawCurve(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final nextNext = i + 2 < points.length ? points[i + 2] : next;
        
        final xMid = (current.dx + next.dx) / 2;
        final yMid = (current.dy + next.dy) / 2;
        
        path.quadraticBezierTo(current.dx, current.dy, xMid, yMid);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawCircle(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    
    final paint2 = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final start = points.first;
    final end = points.last;
    final radius = (end - start).distance / 2;
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    canvas.drawCircle(center, radius, paint2);
  }

  void _drawTriangle(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    
    final paint2 = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final start = points.first;
    final end = points.last;
    
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, start.dy);
    path.lineTo((start.dx + end.dx) / 2, end.dy);
    path.close();
    
    canvas.drawPath(path, paint2);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}