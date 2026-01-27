import 'package:flutter/material.dart';
import '../models/pre_writing_shape.dart';
import '../utils/drawing_service.dart';

class DrawingCanvas extends StatefulWidget {
  final VoidCallback onClear;
  final VoidCallback onUndo;

  const DrawingCanvas({
    super.key, // FIXED: Using super.key
    required this.onClear,
    required this.onUndo,
  });

  @override
  DrawingCanvasState createState() => DrawingCanvasState(); // FIXED: Removed underscore to make it public
}

class DrawingCanvasState extends State<DrawingCanvas> { // FIXED: Made public
  List<DrawingStroke> strokes = [];
  List<DrawingPoint> currentStroke = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentStroke = [
        DrawingPoint(
          point: details.localPosition,
          paint: DrawingService.getDrawingPaint(),
        )
      ];
    });
    
    }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(
        DrawingPoint(
          point: details.localPosition,
          paint: DrawingService.getDrawingPaint(),
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (currentStroke.isNotEmpty) {
        strokes.add(DrawingStroke(
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
          child: CustomPaint(
            painter: DrawingPainter(
              strokes: strokes,
              currentStroke: currentStroke,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> currentStroke;

  DrawingPainter({required this.strokes, required this.currentStroke});

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
//```

//## Summary of Backend API Endpoints You Need:

//### 1. **Load Progress**
//```
//GET /api/child/pre-writing-progress/{childId}
//```

//### 2. **Track Shape Selection**
//```
//POST /api/child/pre-writing/shape-selection
//Body: { childId, shapeId, timestamp }
//```

//### 3. **Log Actions** (Clear, Undo)
//```
//POST /api/child/pre-writing/action
//Body: { childId, actionType, shapeId, timestamp }
//```

//### 4. **Submit for Assessment** (AI Analysis)
//```
//POST /api/child/pre-writing/assess
//Body: { childId, shapeType, drawingData, timestamp }
//Response: { accuracy, completion, suggestions, score }
//```

//### 5. **Track Drawing Start** (Engagement)
//```
//POST /api/child/pre-writing/drawing-start
//Body: { childId, timestamp }
//```

//### 6. **Auto-save Progress**
//```
//POST /api/child/pre-writing/auto-save
//Body: { childId, strokeCount, timestamp }