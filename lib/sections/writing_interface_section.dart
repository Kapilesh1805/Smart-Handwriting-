import 'package:flutter/material.dart';
import '../widgets/unified_writing_canvas.dart';
import '../services/child_service.dart';
import '../services/handwriting_service.dart';
import '../config/api_config.dart';
import '../models/child_profile.dart';

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
  final ScrollController _characterScrollController = ScrollController();

  String currentCharacter = 'A';
  bool isNumberMode = false;
  bool showLetter = true;
  Color selectedColor = Colors.blue;
  double strokeWidth = 5.0;
  String feedback = '';
  bool showFeedback = false;

  // Backend integration variables
  bool isProcessingML = false;
  bool isBackendConnected = false;
  double mlConfidenceScore = 0.0;
  Map<String, dynamic> mlFeedback = {};

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

      // Send to backend for ML analysis
      final analysis = await HandwritingService.analyzeHandwriting(
        childId: selectedChildId!,
        letter: currentCharacter,
        strokesData: strokesData,
        pressureData: pressureData,
      );

      setState(() {
        mlConfidenceScore = analysis.overallScore / 100;
        mlFeedback = {
          'pressure_score': analysis.pressureScore,
          'spacing_score': analysis.spacingScore,
          'formation_score': analysis.formationScore,
          'accuracy_score': analysis.accuracyScore,
          'overall_score': analysis.overallScore,
          'feedback': analysis.feedback,
          'model_used': analysis.modelUsed,
        };
        isProcessingML = false;
        feedback = _generateMLFeedback(mlFeedback);
        showFeedback = true;
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

  String _generateMLFeedback(Map<String, dynamic> result) {
    final double overallScore = (result['overall_score'] ?? 0.0).toDouble();
    final double pressureScore = (result['pressure_score'] ?? 0.0).toDouble();
    final double spacingScore = (result['spacing_score'] ?? 0.0).toDouble();
    final double formationScore = (result['formation_score'] ?? 0.0).toDouble();
    final String feedback = result['feedback'] ?? 'Analysis complete';
    final bool modelUsed = result['model_used'] ?? false;

    String feedbackText = '';

    // Main feedback from ML model
    feedbackText = feedback;

    // Add model status
    if (modelUsed) {
      feedbackText += '\n✅ Real ML model analysis';
    } else {
      feedbackText += '\n📊 Simulated analysis (ML model loading)';
    }

    // Add score breakdown
    feedbackText += '\n\n📈 Score Breakdown:';
    feedbackText += '\n• Overall: ${overallScore.toStringAsFixed(1)}%';
    feedbackText += '\n• Pressure: ${pressureScore.toStringAsFixed(1)}%';
    feedbackText += '\n• Spacing: ${spacingScore.toStringAsFixed(1)}%';
    feedbackText += '\n• Formation: ${formationScore.toStringAsFixed(1)}%';

    // Add recommendations
    if (pressureScore < 70) {
      feedbackText += '\n\n💪 Tip: Apply more consistent pressure on the pen';
    }
    if (spacingScore < 70) {
      feedbackText += '\n💡 Tip: Improve spacing between strokes';
    }
    if (formationScore < 70) {
      feedbackText += '\n✍️ Tip: Work on letter formation and shape';
    }

    return feedbackText;
  }

  void _showBackendNotConnectedMessage() {
    setState(() {
      feedback = '🔌 Backend not connected!\n\nPlease ensure the backend server is running at http://localhost:8000';
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
                      onPressed: () => setState(() => isNumberMode = !isNumberMode),
                      icon: const Icon(Icons.switch_access_shortcut),
                      label: Text(isNumberMode ? 'Numbers' : 'Letters'),
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
          // MIDDLE: Canvas (takes remaining space)
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
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
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => canvasKey.currentState?.undoStroke(),
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
                ElevatedButton.icon(
                  onPressed: () => canvasKey.currentState?.clearCanvas(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                ElevatedButton.icon(
                  onPressed: isProcessingML ? null : _checkWriting,
                  icon: isProcessingML ? null : const Icon(Icons.check),
                  label: Text(isProcessingML ? 'Analyzing...' : 'Check'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: showFeedback ? _buildFeedbackBottomSheet() : null,
    );
  }

  Widget _buildFeedbackBottomSheet() {
    final isError = feedback.contains('❌') || feedback.contains('Error');
    final isWarning = feedback.contains('⚠️');
    final isGood = feedback.contains('✅');

    Color bgColor;
    Color textColor;
    if (isError) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
    } else if (isWarning) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
    } else if (isGood) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: textColor, width: 2)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analysis Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => showFeedback = false),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Scrollable feedback content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                feedback,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}