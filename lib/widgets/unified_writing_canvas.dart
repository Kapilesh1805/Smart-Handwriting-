import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class DrawingPointData {
  final Offset point;
  final Paint paint;
  final double pressure;

  DrawingPointData({required this.point, required this.paint, this.pressure = 1.0});
}

class DrawingStrokeData {
  final List<DrawingPointData> points;
  final DateTime timestamp;

  DrawingStrokeData({required this.points, required DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class UnifiedWritingCanvas extends StatefulWidget {
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback? onStrokesChanged;
  final bool showPressureDots;
  final double canvasWidth;
  final double canvasHeight;
  final Color drawingColor;
  final double strokeWidth;
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const UnifiedWritingCanvas({
    super.key,
    required this.onClear,
    required this.onUndo,
    this.onStrokesChanged,
    this.showPressureDots = false,
    this.canvasWidth = double.infinity,
    this.canvasHeight = 300,
    this.drawingColor = Colors.blue,
    this.strokeWidth = 5.0,
    this.onMouseEnter,
    this.onMouseExit,
  });

  @override
  UnifiedWritingCanvasState createState() => UnifiedWritingCanvasState();
}

class UnifiedWritingCanvasState extends State<UnifiedWritingCanvas> {
  List<DrawingStrokeData> strokes = [];
  List<DrawingPointData> currentStroke = [];
  bool showPressureDots = false;
  bool isMouseOverCanvas = false;

  void _onPointerDown(PointerDownEvent details) {
    setState(() {
      currentStroke = [
        DrawingPointData(
          point: details.localPosition,
          paint: Paint()
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..color = widget.drawingColor
            ..strokeWidth = widget.strokeWidth,
          pressure: details.pressure,
        )
      ];
    });
  }

  void _onPointerMove(PointerMoveEvent details) {
    setState(() {
      currentStroke.add(
        DrawingPointData(
          point: details.localPosition,
          paint: Paint()
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..color = widget.drawingColor
            ..strokeWidth = widget.strokeWidth,
          pressure: details.pressure,
        ),
      );
    });
  }

  void _onPointerUp(PointerUpEvent details) {
    setState(() {
      if (currentStroke.isNotEmpty) {
        strokes.add(DrawingStrokeData(
          points: List.from(currentStroke),
          timestamp: DateTime.now(),
        ));
      }
      currentStroke = [];
    });
    widget.onStrokesChanged?.call();
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
      currentStroke.clear();
    });
    widget.onClear();
    widget.onStrokesChanged?.call();
  }

  void setShowPressureDots(bool v) {
    setState(() {
      showPressureDots = v;
    });
  }

  void undoStroke() {
    setState(() {
      if (strokes.isNotEmpty) {
        strokes.removeLast();
      }
    });
    widget.onUndo();
    widget.onStrokesChanged?.call();
  }

  // Extract strokes for backend submission
  List<Map<String, dynamic>> extractStrokes() {
    List<Map<String, dynamic>> strokesList = [];

    for (var stroke in strokes) {
      List<Map<String, dynamic>> points = [];
      for (var point in stroke.points) {
        // Normalize pressure: raw pressure 0.0-1.0 to 0-100%
        double normalizedPressure = point.pressure * 100;
        normalizedPressure = normalizedPressure.clamp(0.0, 100.0);

        points.add({
          'x': point.point.dx,
          'y': point.point.dy,
          'pressure': normalizedPressure,
        });
      }

      if (points.isNotEmpty) {
        strokesList.add({
          'points': points,
          'color': stroke.points.first.paint.color.toARGB32().toRadixString(16),
          'timestamp': stroke.timestamp.toIso8601String(),
        });
      }
    }

    return strokesList;
  }

  // Get pressure points for analysis
  List<Map<String, dynamic>> getPressurePoints() {
    List<Map<String, dynamic>> pressureData = [];

    for (int i = 0; i < strokes.length; i++) {
      for (int j = 0; j < strokes[i].points.length; j++) {
        final point = strokes[i].points[j];
        double normalizedPressure = point.pressure * 100;
        normalizedPressure = normalizedPressure.clamp(0.0, 100.0);

        pressureData.add({
          'x': point.point.dx,
          'y': point.point.dy,
          'pressure': normalizedPressure,
          'timestamp': i,
        });
      }
    }

    return pressureData;
  }

  @override
  Widget build(BuildContext context) {
    // Use Listener to absorb raw pointer events so the parent scrollable
    // doesn't receive them. Keep only pan handlers on GestureDetector.
    return MouseRegion(
      onEnter: (_) {
        setState(() => isMouseOverCanvas = true);
        widget.onMouseEnter?.call();
      },
      onExit: (_) {
        setState(() => isMouseOverCanvas = false);
        widget.onMouseExit?.call();
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        onPointerMove: (_) {},
        onPointerUp: (_) {},
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent && isMouseOverCanvas) {
            // Absorb scroll event when over canvas
            return;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6FBAFF), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                painter: UnifiedCanvasPainter(
                  strokes: strokes,
                  currentStroke: currentStroke,
                  showPressureDots: showPressureDots || widget.showPressureDots,
                ),
                size: Size(
                  widget.canvasWidth == double.infinity
                      ? MediaQuery.of(context).size.width
                      : widget.canvasWidth,
                  widget.canvasHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnifiedCanvasPainter extends CustomPainter {
  final List<DrawingStrokeData> strokes;
  final List<DrawingPointData> currentStroke;
  final bool showPressureDots;

  UnifiedCanvasPainter({required this.strokes, required this.currentStroke, this.showPressureDots = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (var stroke in strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i].point,
          stroke.points[i + 1].point,
          stroke.points[i].paint,
        );
      }
    }

    // Draw current stroke
    for (int i = 0; i < currentStroke.length - 1; i++) {
      canvas.drawLine(
        currentStroke[i].point,
        currentStroke[i + 1].point,
        currentStroke[i].paint,
      );
    }

    // Draw pressure dots if requested
    if (showPressureDots) {
      final Paint dotPaint = Paint()..style = PaintingStyle.fill;
      for (var stroke in strokes) {
        for (var pt in stroke.points) {
          try {
            final pressure = (pt.paint.strokeWidth - 1.0) / 9.0;
            final radius = (4.0 + (pressure.clamp(0.0, 1.0) * 8.0));
            dotPaint.color = pt.paint.color.withValues(alpha: 0.8);
            canvas.drawCircle(pt.point, radius, dotPaint);
          } catch (e) {
            // ignore drawing errors per point
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
