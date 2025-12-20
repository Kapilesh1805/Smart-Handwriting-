import 'package:flutter/material.dart';

class DrawingPointData {
  final Offset point;
  final Paint paint;

  DrawingPointData({required this.point, required this.paint});
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
  final double canvasWidth;
  final double canvasHeight;
  final Color drawingColor;
  final double strokeWidth;

  const UnifiedWritingCanvas({
    super.key,
    required this.onClear,
    required this.onUndo,
    this.canvasWidth = double.infinity,
    this.canvasHeight = 300,
    this.drawingColor = Colors.blue,
    this.strokeWidth = 5.0,
  });

  @override
  UnifiedWritingCanvasState createState() => UnifiedWritingCanvasState();
}

class UnifiedWritingCanvasState extends State<UnifiedWritingCanvas> {
  List<DrawingStrokeData> strokes = [];
  List<DrawingPointData> currentStroke = [];

  void _onPanStart(DragStartDetails details) {
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
        )
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
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
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (currentStroke.isNotEmpty) {
        strokes.add(DrawingStrokeData(
          points: List.from(currentStroke),
          timestamp: DateTime.now(),
        ));
      }
      currentStroke = [];
    });
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
      currentStroke.clear();
    });
    widget.onClear();
  }

  void undoStroke() {
    setState(() {
      if (strokes.isNotEmpty) {
        strokes.removeLast();
      }
    });
    widget.onUndo();
  }

  // Extract strokes for backend submission
  List<Map<String, dynamic>> extractStrokes() {
    List<Map<String, dynamic>> strokesList = [];

    for (var stroke in strokes) {
      List<Map<String, dynamic>> points = [];
      for (var point in stroke.points) {
        // Normalize pressure: strokeWidth ranges from 1.0 to 10.0
        double normalizedPressure = ((point.paint.strokeWidth - 1.0) / 9.0) * 100;
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
          'color': '${stroke.points.first.paint.color.value.toRadixString(16)}',
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
        double normalizedPressure = ((point.paint.strokeWidth - 1.0) / 9.0) * 100;
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6FBAFF), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: UnifiedCanvasPainter(
              strokes: strokes,
              currentStroke: currentStroke,
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
    );
  }
}

class UnifiedCanvasPainter extends CustomPainter {
  final List<DrawingStrokeData> strokes;
  final List<DrawingPointData> currentStroke;

  UnifiedCanvasPainter({required this.strokes, required this.currentStroke});

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
