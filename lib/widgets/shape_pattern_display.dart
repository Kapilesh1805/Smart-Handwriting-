import 'package:flutter/material.dart';
import '../models/pre_writing_shape.dart';
import '../utils/drawing_service.dart';

class ShapePatternDisplay extends StatelessWidget {
  final ShapeType shapeType;

  const ShapePatternDisplay({super.key, required this.shapeType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: CustomPaint(
        painter: ShapePatternPainter(shapeType: shapeType),
      ),
    );
  }
}

class ShapePatternPainter extends CustomPainter {
  final ShapeType shapeType;

  ShapePatternPainter({required this.shapeType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = DrawingService.getPatternPaint();

    switch (shapeType) {
      case ShapeType.lines:
        _drawLines(canvas, size, paint);
        break;
      case ShapeType.curves:
        _drawCurves(canvas, size, paint);
        break;
      case ShapeType.zigzag:
        _drawZigzag(canvas, size, paint);
        break;
      case ShapeType.circles:
        _drawCircles(canvas, size, paint);
        break;
      case ShapeType.triangle:
        _drawTriangles(canvas, size, paint);
        break;
      case ShapeType.square:
        _drawSquares(canvas, size, paint);
        break;
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    final spacing = size.height / 4;
    for (int i = 1; i <= 3; i++) {
      final y = spacing * i;
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        paint,
      );
    }
  }

  void _drawCurves(Canvas canvas, Size size, Paint paint) {
    final spacing = size.height / 4;
    for (int i = 1; i <= 3; i++) {
      final y = spacing * i;
      final path = Path();
      path.moveTo(20, y);

      for (double x = 20; x < size.width - 20; x += 30) {
        path.quadraticBezierTo(
          x + 15,
          y - 20,
          x + 30,
          y,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawZigzag(Canvas canvas, Size size, Paint paint) {
    final spacing = size.height / 4;
    for (int i = 1; i <= 3; i++) {
      final y = spacing * i;
      final path = Path();
      path.moveTo(20, y);

      bool up = true;
      for (double x = 20; x < size.width - 20; x += 25) {
        path.lineTo(x + 25, up ? y - 20 : y + 20);
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint) {
    final spacing = size.width / 4;
    final yCenter = size.height / 2;
    
    for (int i = 1; i <= 3; i++) {
      final x = spacing * i;
      canvas.drawCircle(Offset(x, yCenter), 30, paint);
    }
  }

  void _drawTriangles(Canvas canvas, Size size, Paint paint) {
    final spacing = size.width / 4;
    final yCenter = size.height / 2;
    
    for (int i = 1; i <= 3; i++) {
      final x = spacing * i;
      final path = Path();
      path.moveTo(x, yCenter - 30);
      path.lineTo(x - 25, yCenter + 20);
      path.lineTo(x + 25, yCenter + 20);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawSquares(Canvas canvas, Size size, Paint paint) {
    final spacing = size.width / 4;
    final yCenter = size.height / 2;
    
    for (int i = 1; i <= 3; i++) {
      final x = spacing * i;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, yCenter), width: 50, height: 50),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}