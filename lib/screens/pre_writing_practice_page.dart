import 'package:flutter/material.dart';

class PreWritingPracticePage extends StatefulWidget {
  final String childId;
  
  const PreWritingPracticePage({
    super.key,
    required this.childId,
  });

  @override
  State<PreWritingPracticePage> createState() => _PreWritingPracticePageState();
}

class _PreWritingPracticePageState extends State<PreWritingPracticePage> {
  String _selectedTool = 'pen';
  List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  
  void _selectTool(String tool) {
    setState(() {
      _selectedTool = tool;
    });
  }

  void _startDrawing(Offset position) {
    _currentStroke = DrawingStroke(
      tool: _selectedTool,
      points: [position],
      color: Colors.orange,
    );
  }

  void _updateDrawing(Offset position) {
    if (_currentStroke == null) return;
    
    setState(() {
      _currentStroke!.points.add(position);
    });
  }

  void _endDrawing() {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _undoStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _saveDrawing() {
    // API CONNECTION: Save drawing to backend
    // POST /api/pre-writing/save-drawing
    // Body: {
    //   "childId": widget.childId,
    //   "strokes": _strokes.map((s) => s.toJson()).toList(),
    //   "timestamp": DateTime.now().toIso8601String()
    // }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drawing saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Smart Board – Pre-Writing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
                              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Left Sidebar - Tools
                    Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Tool Buttons
                          _ToolButton(
                            icon: Icons.edit,
                            label: 'Pen',
                            isSelected: _selectedTool == 'pen',
                            onTap: () => _selectTool('pen'),
                          ),
                          _ToolButton(
                            icon: Icons.straighten,
                            label: 'Line',
                            isSelected: _selectedTool == 'line',
                            onTap: () => _selectTool('line'),
                          ),
                          _ToolButton(
                            icon: Icons.waves,
                            label: 'Curve',
                            isSelected: _selectedTool == 'curve',
                            onTap: () => _selectTool('curve'),
                          ),
                          _ToolButton(
                            icon: Icons.circle_outlined,
                            label: 'Circle',
                            isSelected: _selectedTool == 'circle',
                            onTap: () => _selectTool('circle'),
                          ),
                          _ToolButton(
                            icon: Icons.change_history,
                            label: 'Triangle',
                            isSelected: _selectedTool == 'triangle',
                            onTap: () => _selectTool('triangle'),
                          ),
                          _ToolButton(
                            icon: Icons.cleaning_services,
                            label: 'Eraser',
                            isSelected: _selectedTool == 'eraser',
                            onTap: () => _selectTool('eraser'),
                          ),

                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[700]),
                          const SizedBox(height: 16),

                          // Undo Button
                          _ActionButton(
                            icon: Icons.undo,
                            onTap: _undoStroke,
                          ),
                          _ActionButton(
                            icon: Icons.delete_outline,
                            onTap: _clearCanvas,
                          ),
                          _ActionButton(
                            icon: Icons.volume_up,
                            onTap: () {
                              // API CONNECTION: Play audio guide
                              // GET /api/audio/pre-writing-guide
                            },
                          ),

                          const Spacer(),

                          Divider(color: Colors.grey[700]),
                          const SizedBox(height: 16),

                          // Save Button
                          GestureDetector(
                            onTap: _saveDrawing,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Right Side - Canvas & Practice Area
                    Expanded(
                      child: Column(
                        children: [
                          // Title and Tabs
                          Row(
                            children: [
                              const Text(
                                'Practice Drawing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Lines',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Shapes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Bottom Action Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _BottomActionButton(
                                  icon: Icons.edit,
                                  label: 'Draw',
                                  onTap: () => _selectTool('pen'),
                                ),
                                _BottomActionButton(
                                  icon: Icons.undo,
                                  label: 'Undo',
                                  onTap: _undoStroke,
                                ),
                                _BottomActionButton(
                                  icon: Icons.delete,
                                  label: 'Clear',
                                  onTap: _clearCanvas,
                                ),
                                _BottomActionButton(
                                  icon: Icons.check_circle,
                                  label: 'Check',
                                  onTap: () {
                                    // API CONNECTION: Validate drawing
                                    // POST /api/pre-writing/validate
                                  },
                                ),
                                _BottomActionButton(
                                  icon: Icons.volume_up,
                                  label: '',
                                  onTap: () {
                                    // Play audio
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class DrawingStroke {
  final String tool;
  final List<Offset> points;
  final Color color;

  DrawingStroke({
    required this.tool,
    required this.points,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'tool': tool,
      'color': color.toString(),
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final String currentTool;

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (var stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.tool == 'eraser' ? const Color(0xFFFFF8E7) : stroke.color
      ..strokeWidth = stroke.tool == 'eraser' ? 20 : 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.points.isEmpty) return;

    switch (stroke.tool) {
      case 'pen':
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
      case 'eraser':
        _drawPen(canvas, paint, stroke.points);
        break;
    }
  }

  void _drawPen(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  void _drawLine(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    canvas.drawLine(points.first, points.last, paint);
  }

  void _drawCurve(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final xMid = (points[i - 1].dx + points[i].dx) / 2;
      final yMid = (points[i - 1].dy + points[i].dy) / 2;
      path.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xMid, yMid);
    }
    canvas.drawPath(path, paint);
  }

  void _drawCircle(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final start = points.first;
    final end = points.last;
    final radius = (end - start).distance / 2;
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    canvas.drawCircle(center, radius, paint);
  }

  void _drawTriangle(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final start = points.first;
    final end = points.last;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, start.dy)
      ..lineTo((start.dx + end.dx) / 2, end.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}