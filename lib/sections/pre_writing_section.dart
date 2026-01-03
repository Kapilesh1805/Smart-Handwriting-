import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pre_writing_shape.dart';
import '../models/child_profile.dart';
import '../utils/drawing_service.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';
import '../widgets/unified_writing_canvas.dart';

class PreWritingSection extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const PreWritingSection({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<PreWritingSection> createState() => _PreWritingSectionState();
}

class _PreWritingSectionState extends State<PreWritingSection> {
  late PreWritingShape selectedShape;
  final GlobalKey<UnifiedWritingCanvasState> canvasKey = GlobalKey();
  final ScrollController _shapeScrollController = ScrollController();
  
  // Child selection
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  String? selectedChildName;
  
  // UI state
  bool showShape = true;
  
  // Backend integration variables
  bool isBackendConnected = false;
  bool isProcessingAnalysis = false;
  String feedbackMessage = '';
  bool showFeedback = false;
  Map<String, dynamic> analysisResult = {};

  @override
  void initState() {
    super.initState();
    selectedShape = DrawingService.getShapes().first;
    _checkBackendStatus();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final userId = await Config.getUserId();
      if (userId == null) {
        debugPrint('User not authenticated');
        return;
      }
      final children = await ChildService.getChildren(userId: userId);
      if (mounted) {
        setState(() {
          // Convert Child objects to ChildProfile objects
          childrenList = children.map((child) => ChildProfile(
            id: child.childId,
            name: child.name,
            age: child.age.toString(),
            grade: 'N/A',
            avatar: child.name.isNotEmpty ? child.name[0].toUpperCase() : '👦',
          )).toList();
          // If child was passed via constructor, select it
          if (widget.childId != null) {
            selectedChildId = widget.childId;
            selectedChildName = widget.childName;
          } else if (childrenList.isNotEmpty) {
            selectedChildId = childrenList.first.id;
            selectedChildName = childrenList.first.name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
    }
  }

  @override
  void dispose() {
    _shapeScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:8000/api/health'))
          .timeout(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          isBackendConnected = response.statusCode == 200;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isBackendConnected = false;
        });
      }
      debugPrint('Backend not connected: $e');
    }
  }

  void _selectShape(PreWritingShape shape) {
    setState(() {
      selectedShape = shape;
    });
    canvasKey.currentState?.clearCanvas();
    _scrollToShape(shape);
  }

  void _scrollToShape(PreWritingShape shape) {
    final shapes = DrawingService.getShapes();
    final index = shapes.indexWhere((s) => s.id == shape.id);
    if (index != -1) {
      final offset = (index * 110.0) - (MediaQuery.of(context).size.width / 2) + 55;
      _shapeScrollController.animateTo(
        offset.clamp(0.0, _shapeScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextShape() {
    final shapes = DrawingService.getShapes();
    final currentIndex = shapes.indexWhere((s) => s.id == selectedShape.id);
    if (currentIndex != -1 && currentIndex < shapes.length - 1) {
      _selectShape(shapes[currentIndex + 1]);
    }
  }

  void _previousShape() {
    final shapes = DrawingService.getShapes();
    final currentIndex = shapes.indexWhere((s) => s.id == selectedShape.id);
    if (currentIndex > 0) {
      _selectShape(shapes[currentIndex - 1]);
    }
  }

  void _handleClear() {
    // Optional: Add sound or feedback
  }

  void _handleUndo() {
    // Optional: Add sound or feedback
  }

  void _handleCheck() async {
    final strokes = canvasKey.currentState?.extractStrokes();
    
    if (strokes == null || strokes.isEmpty) {
      setState(() {
        feedbackMessage = 'Please draw the ${selectedShape.type} first!';
        showFeedback = true;
      });
      return;
    }

    if (isBackendConnected) {
      await _sendToBackend();
    } else {
      _showBackendNotConnectedMessage();
    }
  }

  Future<void> _sendToBackend() async {
    setState(() {
      isProcessingAnalysis = true;
      feedbackMessage = 'Analyzing shape...';
      showFeedback = true;
    });

    try {
      final strokesData = canvasKey.currentState?.extractStrokes() ?? [];
      final pressureData = canvasKey.currentState?.getPressurePoints() ?? [];

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/analyze-pre-writing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shape_type': selectedShape.type.toString().split('.').last,
          'strokes': strokesData,
          'pressurePoints': pressureData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          analysisResult = result;
          isProcessingAnalysis = false;
          feedbackMessage = _generateFeedback(result);
          showFeedback = true;
        });
      } else {
        _showError('Analysis failed');
      }
    } catch (e) {
      setState(() {
        isProcessingAnalysis = false;
        isBackendConnected = false;
      });
      _showBackendNotConnectedMessage();
      debugPrint('Error sending to backend: $e');
    }
  }

  String _generateFeedback(Map<String, dynamic> result) {
    String feedbackText = '';
    
    // Accuracy feedback
    double accuracy = (result['accuracy'] ?? 0.0).toDouble();
    if (accuracy >= 0.85) {
      feedbackText += '✅ Excellent accuracy! (${(accuracy * 100).toStringAsFixed(0)}%)\n';
    } else if (accuracy >= 0.70) {
      feedbackText += '👍 Good accuracy! (${(accuracy * 100).toStringAsFixed(0)}%)\n';
    } else {
      feedbackText += '⚠️ Accuracy needs work. (${(accuracy * 100).toStringAsFixed(0)}%)\n';
    }

    // Suggestions
    List<dynamic> suggestions = result['suggestions'] ?? [];
    if (suggestions.isNotEmpty) {
      feedbackText += '\n💡 Tips:\n';
      for (var i = 0; i < suggestions.length && i < 3; i++) {
        feedbackText += '• ${suggestions[i]}\n';
      }
    }

    return feedbackText;
  }

  void _showBackendNotConnectedMessage() {
    setState(() {
      feedbackMessage = '🔌 Backend not connected!\n\nPlease ensure the backend server is running at http://localhost:8000';
      showFeedback = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Backend unavailable - AI analysis disabled'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      feedbackMessage = '❌ Error: $message';
      showFeedback = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Writing Practice'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // CHILD SELECTION DROPDOWN
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Select Child:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedChildId,
                    isExpanded: true,
                    hint: const Text('Choose a child'),
                    items: childrenList.map((child) {
                      return DropdownMenuItem<String>(
                        value: child.id,
                        child: Text(child.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final child = childrenList.firstWhere((c) => c.id == value);
                        setState(() {
                          selectedChildId = value;
                          selectedChildName = child.name;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // TOP: Shape Selector with toggle and arrows
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        showShape ? selectedShape.icon : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => showShape = !showShape),
                      icon: Icon(showShape ? Icons.visibility : Icons.visibility_off),
                      color: Colors.blue,
                      iconSize: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Shape selector - hidden when eye is off, with arrow navigation
                if (showShape)
                  Row(
                    children: [
                      IconButton(
                        onPressed: _previousShape,
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.blue,
                        iconSize: 24,
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ListView.builder(
                            controller: _shapeScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: DrawingService.getShapes().length,
                            itemBuilder: (ctx, idx) {
                              final shape = DrawingService.getShapes()[idx];
                              final isSelected = shape.type == selectedShape.type;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _selectShape(shape),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue : Colors.white,
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        shape.icon,
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.blue,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextShape,
                        icon: const Icon(Icons.arrow_forward),
                        color: Colors.blue,
                        iconSize: 24,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // MIDDLE: Canvas (takes remaining space)
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: UnifiedWritingCanvas(
                key: canvasKey,
                onClear: _handleClear,
                onUndo: _handleUndo,
                canvasHeight: double.infinity,
              ),
            ),
          ),
          // BOTTOM: Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => canvasKey.currentState?.clearCanvas(),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
                ElevatedButton.icon(
                  onPressed: () => canvasKey.currentState?.undoStroke(),
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
                ElevatedButton.icon(
                  onPressed: isProcessingAnalysis ? null : _handleCheck,
                  icon: Icon(isProcessingAnalysis ? Icons.hourglass_bottom : Icons.check_circle_outline),
                  label: Text(isProcessingAnalysis ? 'Analyzing...' : 'Check'),
                ),
              ],
            ),
          ),
          // Feedback message
          if (showFeedback)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: SingleChildScrollView(
                child: Text(
                  feedbackMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
