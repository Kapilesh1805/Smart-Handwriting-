import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../widgets/unified_writing_canvas.dart';
import '../services/child_service.dart';
import '../services/handwriting_service.dart';
import '../config/api_config.dart';
import '../utils/pressure_utils.dart';
import '../models/child_profile.dart';
import '../utils/scroll_lock_manager.dart';

class WritingInterfaceSection extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const WritingInterfaceSection({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<WritingInterfaceSection> createState() =>
      _WritingInterfaceSectionState();
}

class _WritingInterfaceSectionState extends State<WritingInterfaceSection> {
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  String? selectedChildName;

  final List<String> letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  final List<String> numbers = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  // Canvas reference
  final GlobalKey<UnifiedWritingCanvasState> canvasKey = GlobalKey();
  final GlobalKey repaintBoundaryKey = GlobalKey();
  final ScrollController _characterScrollController = ScrollController();

  String currentCharacter = 'A';
  bool isNumberMode = false;
  bool showLetter = true;
  Color selectedColor = Colors.blue;
  double strokeWidth = 5.0;
  String feedback = '';
  bool showFeedback = false;
  
  // ✅ COMPUTED PROPERTY: Always sync with actual mode state
  String get currentEvaluationMode => isNumberMode ? 'number' : 'alphabet';

  // Backend integration variables
  bool isProcessingML = false;
  bool isBackendConnected = false;
  HandwritingAnalysis? _analysisResult;
  int lastStrokeCount = 0;
  double? lastPressure;
  double? rawPressure;
  int? pressurePointCount;
  bool showRawPressure = false;
  List<dynamic>? rawPressurePoints;

  List<String> get currentList => isNumberMode ? numbers : letters;

  @override
  void dispose() {
    _characterScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
    _loadChildren();
    
    // Pre-select child if passed from navigation
    if (widget.childId != null) {
      selectedChildId = widget.childId;
      selectedChildName = widget.childName;
    }
  }

  Future<void> _loadChildren() async {
    try {
      final userId = await Config.getUserId();
      if (userId == null) {
        debugPrint('User not authenticated');
        return;
      }
      final children = await ChildService.getChildren(userId: userId);
      setState(() {
        // Convert Child objects to ChildProfile objects
        childrenList = children.map((child) => ChildProfile(
          id: child.childId,
          name: child.name,
          age: child.age.toString(),
          grade: 'N/A',
          avatar: child.name.isNotEmpty ? child.name[0].toUpperCase() : '👦',
        )).toList();
        
        // If child was passed, select it; otherwise select first
        if (widget.childId != null) {
          selectedChildId = widget.childId;
          selectedChildName = widget.childName;
        } else if (childrenList.isNotEmpty) {
          selectedChildId = childrenList.first.id;
          selectedChildName = childrenList.first.name;
        }
      });
    } catch (e) {
      debugPrint('Error loading children: $e');
    }
  }

  Future<void> _checkBackendStatus() async {
    try {
      final isConnected = await HandwritingService.checkBackendStatus();
      setState(() {
        isBackendConnected = isConnected;
      });
      if (isConnected) {
        debugPrint('✅ Backend connected');
      }
    } catch (e) {
      setState(() {
        isBackendConnected = false;
      });
      debugPrint('Backend not connected: $e');
    }
  }

  void _selectCharacter(String char) {
    setState(() {
      currentCharacter = char;
      canvasKey.currentState?.clearCanvas();
      feedback = '';
      showFeedback = false;
    });
    _scrollToCharacter(char);
  }

  void _scrollToCharacter(String char) {
    final index = currentList.indexOf(char);
    if (index != -1) {
      // Each character button is 40 wide + 8 padding (48 total)
      final offset = (index * 48.0) - (MediaQuery.of(context).size.width / 2) + 24;
      _characterScrollController.animateTo(
        offset.clamp(0.0, _characterScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextCharacter() {
    final currentIndex = currentList.indexOf(currentCharacter);
    if (currentIndex < currentList.length - 1) {
      _selectCharacter(currentList[currentIndex + 1]);
    }
  }

  void _previousCharacter() {
    final currentIndex = currentList.indexOf(currentCharacter);
    if (currentIndex > 0) {
      _selectCharacter(currentList[currentIndex - 1]);
    }
  }

  void _checkWriting() async {
    final strokes = canvasKey.currentState?.extractStrokes();
    
    if (strokes == null || strokes.isEmpty) {
      setState(() {
        feedback = 'Please write the $currentCharacter first!';
        showFeedback = true;
      });
      return;
    }

    // Compute and display local pressure immediately from canvas so user sees feedback
    final localPressureData = canvasKey.currentState?.getPressurePoints() ?? [];
    if (localPressureData.isNotEmpty) {
      debugPrint('First few pressures: ${localPressureData.take(5).map((p) => p['pressure'])}');
      final avg = PressureUtils.computeAveragePressure(localPressureData);
      setState(() {
        lastPressure = avg;
        rawPressure = localPressureData.last['pressure'];
        pressurePointCount = localPressureData.length;
        rawPressurePoints = localPressureData;
      });
    }

    if (isBackendConnected) {
      await _sendToMLModel();
    } else {
      _showBackendNotConnectedMessage();
    }
  }

  Future<void> _sendToMLModel() async {
    if (selectedChildId == null) {
      _showError('Please select a child first');
      return;
    }

    setState(() {
      isProcessingML = true;
      feedback = '🔄 Analyzing handwriting...';
      showFeedback = true;
    });

    try {
      // Extract drawing data from canvas
      final strokesData = canvasKey.currentState?.extractStrokes() ?? [];
      final pressureData = canvasKey.currentState?.getPressurePoints() ?? [];

      if (strokesData.isEmpty && pressureData.isEmpty) {
        _showError('Please write something on the canvas first');
        setState(() {
          isProcessingML = false;
        });
        return;
      }

      debugPrint('📊 Canvas data - Strokes: ${strokesData.length}, Pressure points: ${pressureData.length}');

      // ✅ Capture canvas as image and convert to base64
      String? imageBase64;
      try {
        imageBase64 = await _captureCanvasAsBase64();
        if (imageBase64 != null) {
          debugPrint('📸 Canvas captured as image (${imageBase64.length} bytes)');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to capture canvas image: $e');
      }

      // Send to backend for ML analysis (now with image!)
      debugPrint('📤 DEBUG: Sending request with evaluationMode=$currentEvaluationMode (isNumberMode=$isNumberMode)');
      debugPrint('📝 Character: $currentCharacter, stroke count: ${strokesData?.length ?? 0}');
      
      lastStrokeCount = strokesData?.length ?? 0;
      
      final analysis = await HandwritingService.analyzeHandwriting(
        childId: selectedChildId!,
        letter: currentCharacter,
        evaluationMode: currentEvaluationMode,
        imageBase64: imageBase64,
        strokesData: strokesData,
        pressureData: pressureData,
      );
      // Store the typed HandwritingAnalysis directly.

      setState(() {
        _analysisResult = analysis;
        isProcessingML = false;
        showFeedback = true;
        // If backend returned a numeric pressure and no frontend pressure, use backend
        if (_analysisResult?.pressure != null && lastPressure == null) {
          lastPressure = _analysisResult!.pressure;
        }
        // Preserve any raw pressure points returned by backend
        rawPressurePoints = _analysisResult?.rawPressurePoints ?? rawPressurePoints;
      });

      debugPrint('✅ Analysis complete');
    } catch (e) {
      setState(() {
        isProcessingML = false;
      });
      _showError('Analysis failed: ${e.toString().replaceFirst('Exception: ', '')}');
      debugPrint('Error analyzing handwriting: $e');
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
            Uint8List pngBytes = byteData.buffer.asUint8List();
            
            // Process the image: crop to bounding box, add padding, center, scale to 256x256
            pngBytes = _processCanvasImage(pngBytes);
            
            final String base64Image = base64Encode(pngBytes);
            return base64Image;  // Return base64 without data URL prefix
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

  Uint8List _processCanvasImage(Uint8List pngBytes) {
    final originalImage = img.decodePng(pngBytes);
    if (originalImage == null) return pngBytes;
    
    // Find bounding box of non-white pixels
    int minX = originalImage.width, minY = originalImage.height, maxX = 0, maxY = 0;
    bool hasStrokes = false;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r, g = pixel.g, b = pixel.b;
        if (r < 250 || g < 250 || b < 250) {  // Not white
          hasStrokes = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    
    if (!hasStrokes) return pngBytes;
    
    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    
    // Crop
    final cropped = img.copyCrop(originalImage, x: minX, y: minY, width: width, height: height);
    
    // Add 12% padding
    final padX = (width * 0.12).round();
    final padY = (height * 0.12).round();
    final paddedWidth = width + 2 * padX;
    final paddedHeight = height + 2 * padY;
    final padded = img.Image(width: paddedWidth, height: paddedHeight);
    img.fill(padded, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(padded, cropped, dstX: padX, dstY: padY);
    
    // Resize to 256x256
    final scaled = img.copyResize(padded, width: 256, height: 256, interpolation: img.Interpolation.linear);
    
    debugPrint('Canvas processed: original ${originalImage.width}x${originalImage.height}, cropped ${width}x${height}, final 256x256');
    
    return img.encodePng(scaled);
  }

  // Legacy feedback generation removed. Rendering is now driven directly
  // by `backendResult` in `_buildFeedback()` per frontend contract.

  void _showBackendNotConnectedMessage() {
    setState(() {
      feedback = '🔌 Backend not connected!\n\nPlease ensure the backend server is running at ${Config.apiBaseUrl}';
      showFeedback = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Backend unavailable - using local analysis'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      feedback = '❌ Error: $message';
      showFeedback = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Practice'),
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

            // TOP: Letter/Number Selector
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
                          showLetter ? currentCharacter : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() => showLetter = !showLetter),
                        icon: Icon(showLetter ? Icons.visibility : Icons.visibility_off),
                        color: Colors.blue,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => isNumberMode = !isNumberMode);
                          debugPrint('🔄 Mode toggled: isNumberMode=$isNumberMode, evaluationMode=$currentEvaluationMode');
                        },
                        icon: const Icon(Icons.switch_access_shortcut),
                        label: Text(isNumberMode ? 'Numbers' : 'Letters'),
                      ),
                      const SizedBox(width: 8),
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
                  // Character selector - hidden when eye is off, with arrow navigation
                  if (showLetter)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _previousCharacter,
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.blue,
                          iconSize: 24,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ListView.builder(
                              controller: _characterScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: currentList.length,
                              itemBuilder: (ctx, idx) {
                                final char = currentList[idx];
                                final isSelected = char == currentCharacter;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _selectCharacter(char),
                                  child: Container(
                                    width: 40,
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
                                        char,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.blue,
                                        ),
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
                          onPressed: _nextCharacter,
                          icon: const Icon(Icons.arrow_forward),
                          color: Colors.blue,
                          iconSize: 24,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // MIDDLE: Canvas (fixed height so it doesn't expand)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              height: 400,
              child: RepaintBoundary(
                key: repaintBoundaryKey,
                child: UnifiedWritingCanvas(
                  key: canvasKey,
                  onClear: () {},
                  onUndo: () {},
                  canvasHeight: double.infinity,
                  drawingColor: selectedColor,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            // BOTTOM: Action buttons
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Show last pressure value if available
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('Pressure: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${pressurePointCount ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => canvasKey.currentState?.undoStroke(),
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      canvasKey.currentState?.clearCanvas();
                      setState(() {
                        feedback = '';
                        showFeedback = false;
                      });
                      debugPrint('✅ Canvas cleared, ready for new letter');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessingML ? null : _checkWriting,
                    icon: isProcessingML ? null : const Icon(Icons.check),
                    label: Text(isProcessingML ? 'Analyzing...' : 'Check'),
                  ),
                  const SizedBox(width: 8),
                  // Toggle raw pressure view
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showRawPressure = !showRawPressure;
                      });
                      // Also tell the canvas to visualize pressure dots
                      canvasKey.currentState?.setShowPressureDots(showRawPressure);
                    },
                    icon: Icon(
                      showRawPressure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blue,
                    ),
                    tooltip: 'Show raw pressure points',
                  ),
                ],
              ),
            ),
            // Raw pressure points list (debug)
            if (showRawPressure && rawPressurePoints != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 100,
                child: ValueListenableBuilder<bool>(
                  valueListenable: scrollLockManager.isScrollLocked,
                  builder: (context, locked, _) {
                    return SingleChildScrollView(
                      physics: locked
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
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
                    );
                  },
                ),
              ),
            ],
            if (showFeedback) _buildFeedback(),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedback() {
    // Render UI strictly from typed HandwritingAnalysis when available.
    Color bgColor = Colors.blue.shade50;
    Color textColor = Colors.blue.shade900;
    Widget content;

    if (_analysisResult != null) {
      final legibilityStatus = _analysisResult!.legibilityStatus;
      final isPass = legibilityStatus == 'PASS';

      if (isPass) {
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;

        final List<Widget> lines = [];
        lines.add(const Text('✅ Correct Letter', style: TextStyle(fontWeight: FontWeight.bold)));
        lines.add(const SizedBox(height: 8));

        if (_analysisResult!.ocrConfidence != null) {
          lines.add(Text('Confidence: ${_analysisResult!.ocrConfidence!.toStringAsFixed(1)}%', style: TextStyle(color: textColor)));
        }

        if (_analysisResult!.qualityLabel != null) {
          lines.add(const SizedBox(height: 4));
          lines.add(Text('Quality: ${_analysisResult!.qualityLabel}', style: TextStyle(color: textColor)));
        }

        if (_analysisResult!.qualityScore != null) {
          lines.add(const SizedBox(height: 4));
          lines.add(Text('Quality Score: ${_analysisResult!.qualityScore!.toStringAsFixed(1)}%', style: TextStyle(color: textColor)));
        }

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        );
      } else {
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;

        final List<Widget> lines = [];
        lines.add(const Text('❌ Incorrect Letter', style: TextStyle(fontWeight: FontWeight.bold)));
        lines.add(const SizedBox(height: 8));

        if (_analysisResult!.qualityLabel != null) {
          lines.add(Text('Quality: ${_analysisResult!.qualityLabel}', style: TextStyle(color: textColor)));
        }

        if (_analysisResult!.qualityScore != null) {
          lines.add(const SizedBox(height: 4));
          lines.add(Text('Quality Score: ${_analysisResult!.qualityScore!.toStringAsFixed(1)}%', style: TextStyle(color: textColor)));
        }

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        );
      }
    } else {
      // No backend response yet: show generic feedback text
      final isError = feedback.contains('❌') || feedback.contains('Error');
      final isWarning = feedback.contains('⚠️');
      final isGood = feedback.contains('✅');
      if (isError) {
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
      } else if (isWarning) {
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
      } else if (isGood) {
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
      }

      content = Text(feedback, style: TextStyle(fontSize: 13, height: 1.5, color: textColor));
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: textColor, width: 2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analysis Result',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => showFeedback = false),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Feedback content (not scrollable - page itself scrolls)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle(
              style: TextStyle(fontSize: 13, height: 1.5, color: textColor),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}