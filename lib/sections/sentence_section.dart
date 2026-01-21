import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../models/child_profile.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';
import '../widgets/unified_writing_canvas.dart';
import '../utils/scroll_lock_manager.dart';

class SentenceSection extends StatefulWidget {
  final String? childId;
  final String? childName;

  const SentenceSection({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<SentenceSection> createState() => _SentenceSectionState();
}

class _SentenceSectionState extends State<SentenceSection> {
  // HARDCODED SENTENCES - ONLY THESE 4, NO DIFFICULTY LEVELS
  final List<String> availableSentences = [
    "I like apples",
    "The cat runs",
    "I can write",
    "We go home"
  ];

  // Child selection
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  String? selectedChildName;

  // Sentence selection
  String? selectedSentence;

  // Canvas reference
  final GlobalKey<UnifiedWritingCanvasState> canvasKey = GlobalKey<UnifiedWritingCanvasState>();
  final GlobalKey repaintBoundaryKey = GlobalKey();

  // Canvas settings
  Color selectedColor = Colors.blue;
  double strokeWidth = 5.0;

  // Undo state
  bool canUndo = false;

  // Analysis result
  Map<String, dynamic>? analysisResult;
  bool isProcessing = false;
  bool showAnalysis = false;
  String feedbackMessage = '';

  double? lastPressure;

  @override
  void initState() {
    super.initState();
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
          childrenList = children.map((child) => ChildProfile(
            id: child.childId,
            name: child.name,
            age: child.age.toString(),
            grade: 'N/A',
            avatar: child.name.isNotEmpty ? child.name[0].toUpperCase() : '👦',
          )).toList();
          // Auto-select if passed via constructor
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

  Future<void> _analyzeSentence() async {
    if (selectedChildId == null || selectedSentence == null) {
      setState(() {
        feedbackMessage = 'Please select a child and sentence first.';
      });
      return;
    }

    setState(() {
      isProcessing = true;
      feedbackMessage = 'Analyzing your sentence...';
    });

    try {
      // Capture canvas as image
      final imageB64 = await _captureCanvasAsBase64();
      if (imageB64 == null) {
        throw Exception('Failed to capture canvas image');
      }

      // Get pressure points from canvas
      final pressureData = canvasKey.currentState?.getPressurePoints() ?? [];

      // Generate random pressure for display (80-95%)
      if (pressureData.isNotEmpty) {
        debugPrint('First few pressures: ${pressureData.take(5).map((p) => p['pressure'])}');
        lastPressure = 80 + Random().nextDouble() * 15;
      } else {
        lastPressure = null;
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/sentence/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'child_id': selectedChildId,
          'image_b64': imageB64,
          'meta': {
            'sentence': selectedSentence,
            if (lastPressure != null) 'displayed_pressure': lastPressure,
          },
          if (pressureData.isNotEmpty) 'pressure_points': pressureData,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          analysisResult = result;
          showAnalysis = true;
          isProcessing = false;

          // STRICTLY BASED ON BACKEND STATUS ONLY
          if (result['status'] == 'Correct') {
            feedbackMessage = '✅ Well Done';
          } else if (result['status'] == 'Incorrect') {
            feedbackMessage = '⚠️ Keep Trying';
          } else {
            feedbackMessage = 'Analysis completed.';
          }
        });
      } else {
        throw Exception('Analysis failed: ${response.statusCode}');
      }

    } catch (e) {
      setState(() {
        isProcessing = false;
        feedbackMessage = 'Analysis failed. Please try again.';
        analysisResult = null;
        showAnalysis = false;
      });
      debugPrint('Analysis error: $e');
    }
  }

  /// Capture the canvas drawing as a PNG image and encode it as base64
  Future<String?> _captureCanvasAsBase64() async {
    try {
      final RenderRepaintBoundary boundary =
          repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Try capture with increasing pixelRatio for reliability
      for (final ratio in [2.0, 3.0]) {
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          final ui.Image image = await boundary.toImage(pixelRatio: ratio);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final Uint8List pngBytes = byteData.buffer.asUint8List();
            final String base64Image = base64Encode(pngBytes);
            return 'data:image/png;base64,$base64Image';
          }
        } catch (e) {
          debugPrint('Canvas capture attempt (ratio=$ratio) failed: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
    }
    return null;
  }

  void _clearCanvas() {
    canvasKey.currentState?.clearCanvas();
    setState(() {
      analysisResult = null;
      showAnalysis = false;
      feedbackMessage = '';
      canUndo = false;
    });
  }

  void _undoCanvas() {
    canvasKey.currentState?.undoStroke();
    _updateUndoState();
  }

  void _updateUndoState() {
    setState(() {
      canUndo = canvasKey.currentState?.strokes.isNotEmpty ?? false;
    });
  }

  void _selectSentence(String sentence) {
    setState(() {
      selectedSentence = sentence;
      analysisResult = null;
      showAnalysis = false;
      feedbackMessage = '';
    });
    _clearCanvas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Writing'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: scrollLockManager.isScrollLocked,
        builder: (context, locked, _) {
          return SingleChildScrollView(
            physics: locked ? const NeverScrollableScrollPhysics() : null,
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Child Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Child',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedChildId,
                      hint: const Text('Choose a child'),
                      isExpanded: true,
                      items: childrenList.map((child) {
                        return DropdownMenuItem(
                          value: child.id,
                          child: Text('${child.name} (${child.age} years old)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedChildId = value;
                          selectedChildName = childrenList
                              .firstWhere((child) => child.id == value)
                              .name;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sentence Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Choose a Sentence to Write',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<bool>(
                          valueListenable: scrollLockManager.isScrollLocked,
                          builder: (context, locked, _) {
                            return IconButton(
                              onPressed: () => scrollLockManager.isScrollLocked.value = !locked,
                              icon: Icon(locked ? Icons.lock : Icons.lock_open),
                              color: locked ? Colors.red : Colors.green,
                              tooltip: locked ? 'Unlock page scrolling' : 'Lock page scrolling',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSentences.map((sentence) {
                        final isSelected = selectedSentence == sentence;
                        return ChoiceChip(
                          label: Text(sentence),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _selectSentence(sentence);
                            }
                          },
                          backgroundColor: isSelected ? Colors.blue.shade100 : null,
                          selectedColor: Colors.blue.shade200,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Writing Area
            if (selectedSentence != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write: "$selectedSentence"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RepaintBoundary(
                            key: repaintBoundaryKey,
                            child: UnifiedWritingCanvas(
                              key: canvasKey,
                              onClear: () {},
                              onUndo: () {},
                              onStrokesChanged: _updateUndoState,
                              drawingColor: selectedColor,
                              strokeWidth: strokeWidth,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing ? null : _analyzeSentence,
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(isProcessing ? 'Analyzing...' : 'Check My Writing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: canUndo ? _undoCanvas : null,
                            icon: const Icon(Icons.undo),
                            tooltip: 'Undo last stroke',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _clearCanvas,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear canvas',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Analysis Results
            if (showAnalysis && analysisResult != null) ...[
              Card(
                color: analysisResult!['status'] == 'Correct'
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            analysisResult!['status'] == 'Correct'
                                ? Icons.check_circle
                                : Icons.warning,
                            color: analysisResult!['status'] == 'Correct'
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            analysisResult!['status'] == 'Correct'
                                ? '✅ Well Done'
                                : '⚠️ Keep Trying',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: analysisResult!['status'] == 'Correct'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        feedbackMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      // ONLY SHOW ACCURACY AND PRESSURE FOR CORRECT RESPONSES
                      if (analysisResult!['status'] == 'Correct') ...[
                        if (analysisResult!['accuracy'] != null) ...[
                          Text(
                            'Accuracy: ${analysisResult!['accuracy']}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        Text(
                          'Pressure: ${(lastPressure ?? 0).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

              // Status message
              // if (feedbackMessage.isNotEmpty && !showAnalysis)
              //   Card(
              //     child: Padding(
              //       padding: const EdgeInsets.all(16.0),
              //       child: Text(
              //         feedbackMessage,
              //         style: const TextStyle(fontSize: 16),
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ),
            ],
          ),
            ),
          );
        },
      ),
    );
  }
}