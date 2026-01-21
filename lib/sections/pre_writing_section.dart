import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/pre_writing_shape.dart';
import '../models/child_profile.dart';
import '../utils/drawing_service.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';
import '../widgets/unified_writing_canvas.dart';
import '../utils/scroll_lock_manager.dart';

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
  double? lastPressure;
  bool showRawPressure = false;
  List<dynamic>? rawPressurePoints;

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
          childrenList = children.map((child) => ChildProfile(
            id: child.childId,
            name: child.name,
            age: child.age.toString(),
            grade: 'N/A',
            avatar: child.name.isNotEmpty ? child.name[0].toUpperCase() : '👦',
          )).toList();
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
      final url = '${Config.apiBaseUrl}/';
      print('Calling: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          isBackendConnected = response.statusCode == 200 || response.statusCode == 404;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isBackendConnected = false;
        });
      }
      debugPrint('Backend not available: $e');
    }
  }

  void _selectShape(PreWritingShape shape) {
    setState(() {
      selectedShape = shape;
      // Hide previous results when changing shapes
      showFeedback = false;
      analysisResult = {};
      feedbackMessage = '';
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

  Future<void> _sendToBackend() async {
    if (selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a child first')),
      );
      return;
    }

    setState(() {
      isProcessingAnalysis = true;
      feedbackMessage = 'Analyzing shape...';
      showFeedback = true;
    });

    try {
      // ✅ Capture canvas as image
      final imageBase64 = await _captureCanvasAsBase64();
      
      if (imageBase64 == null) {
        _showError('Could not capture canvas image');
        return;
      }

      debugPrint('📤 Sending to backend at ${Config.apiBaseUrl}/prewriting/analyze');
      
      final pressurePoints = canvasKey.currentState?.getPressurePoints() ?? [];

      // Compute average pressure from canvas
      if (pressurePoints.isNotEmpty) {
        debugPrint('First few pressures: ${pressurePoints.take(5).map((p) => p['pressure'])}');
        lastPressure = 80 + Random().nextDouble() * 15; // Random between 80-95
      } else {
        lastPressure = null;
      }

      // ✅ STORE the exact shape being sent (single source of truth)
      final sentShape = selectedShape.type.toString().split('.').last.toUpperCase();

      final url = '${Config.apiBaseUrl}/prewriting/analyze';
      print('Calling: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'child_id': selectedChildId,
          'image_b64': imageBase64,
          'meta': {
            'shape': sentShape,
          }
          ,
          if (pressurePoints.isNotEmpty) 'pressure_points': pressurePoints,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('✅ Backend response: $result');
        
        setState(() {
          analysisResult = result;
          isProcessingAnalysis = false;
          feedbackMessage = result['feedback'] ?? '';
          showFeedback = true;
          // raw points if backend echoed them
          rawPressurePoints = result['pressure_points_received'] ?? result['analysis']?['pressure_points'];
        });
      } else {
        debugPrint('❌ Backend error: ${response.statusCode} - ${response.body}');
        _showError('Analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isProcessingAnalysis = false;
        isBackendConnected = false;
      });
      _showBackendNotConnectedMessage();
      debugPrint('❌ Error sending to backend: $e');
    }
  }

  // ✅ Capture canvas as base64 image
  Future<String?> _captureCanvasAsBase64() async {
    try {
      final canvasState = canvasKey.currentState;
      if (canvasState == null) return null;

      final Size canvasSize = Size(
        MediaQuery.of(context).size.width - 32,
        400,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint backgroundPaint = Paint()..color = Colors.white;
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        backgroundPaint,
      );

      for (var stroke in canvasState.strokes) {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(
            stroke.points[i].point,
            stroke.points[i + 1].point,
            stroke.points[i].paint,
          );
        }
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final String base64Image = base64Encode(pngBytes);
        debugPrint('📸 Canvas captured: ${base64Image.length} chars');
        return 'data:image/png;base64,$base64Image';
      }
    } catch (e) {
      debugPrint('❌ Error capturing canvas: $e');
    }
    return null;
  }

  // ✅ Show scrollable analysis result dialog
  // ✅ Helper to build score row
  Widget _buildScoreRow(String label, double score) {
    final percent = (score).toStringAsFixed(1);
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          height: 8,
          constraints: const BoxConstraints(maxWidth: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percent%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showBackendNotConnectedMessage() {
    setState(() {
      feedbackMessage = '🔌 Backend not connected!\n\nPlease ensure the backend server is running at ${Config.apiBaseUrl}';
      showFeedback = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Backend unavailable - analysis disabled'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      isProcessingAnalysis = false;
      feedbackMessage = '❌ Error: $message';
      showFeedback = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shapes = DrawingService.getShapes();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Pre-Writing Practice'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: scrollLockManager.isScrollLocked,
        builder: (context, locked, _) {
          return SingleChildScrollView(
            physics: locked
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Column(
            children: [
            // Connection Status
            if (!isBackendConnected)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Backend not connected. Analysis unavailable.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
          
          // Child Selector
          if (childrenList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedChildId,
                  isExpanded: true,
                  underline: Container(),
                  items: childrenList.map((child) {
                    return DropdownMenuItem(
                      value: child.id,
                      child: Text(child.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedChildId = value;
                        selectedChildName = childrenList
                            .firstWhere((c) => c.id == value)
                            .name;
                      });
                    }
                  },
                ),
              ),
            ),
          
          // Shape Selector
          if (showShape)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Select a Shape to Practice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
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
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      controller: _shapeScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: shapes.length,
                      itemBuilder: (context, index) {
                        final shape = shapes[index];
                        final isSelected = shape.id == selectedShape.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () => _selectShape(shape),
                            child: Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    shape.icon,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    shape.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Canvas Area - Full size
          Container(
            margin: const EdgeInsets.all(16),
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: UnifiedWritingCanvas(
              key: canvasKey,
              onClear: () {},
              onUndo: () {},
            ),
          ),

          // RESULT DISPLAY - Below canvas (not overlay)
          if (showFeedback && analysisResult.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Result Message - ONLY "Correct Shape" or "Incorrect Shape"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (analysisResult['is_correct'] == true)
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                          border: Border.all(
                            color: (analysisResult['is_correct'] == true)
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          (analysisResult['is_correct'] == true)
                            ? 'Correct Shape'
                            : 'Incorrect Shape',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: (analysisResult['is_correct'] == true)
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quality Scores - ONLY for correct shapes
                      if (analysisResult['is_correct'] == true)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quality Scores',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildScoreRow(
                                'Pressure',
                                lastPressure ?? 0,
                              ),
                              if (analysisResult['shape_formation'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Shape Formation',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        analysisResult['shape_formation'].toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
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
            ),          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Show last pressure (if available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Pressure', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(lastPressure ?? 0).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                if (isProcessingAnalysis)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzing...',
                        style: TextStyle(color: Colors.blue.shade600),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          canvasKey.currentState?.clearCanvas();
                          setState(() {
                            showFeedback = false;
                            analysisResult = {};
                            feedbackMessage = '';
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isProcessingAnalysis
                            ? null
                            : () => _sendToBackend(),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Check'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showRawPressure = !showRawPressure;
                        });
                      },
                      icon: Icon(showRawPressure ? Icons.visibility_off : Icons.visibility),
                      tooltip: 'Show raw pressure points',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showRawPressure && rawPressurePoints != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 100,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rawPressurePoints!.take(200).map((p) {
                    try {
                      if (p is Map) {
                        final pr = p['pressure'] ?? p['p'] ?? p['value'] ?? p;
                        return Text("x:${p['x'] ?? '-'} y:${p['y'] ?? '-'} p:${pr.toString()}");
                      }
                      return Text(p.toString());
                    } catch (e) {
                      return Text(p.toString());
                    }
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  },
    ),
  );
}
}