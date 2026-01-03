import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/unified_writing_canvas.dart';
import '../services/child_service.dart';
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
      final response = await http
          .get(Uri.parse('http://localhost:8000/api/health'))
          .timeout(const Duration(seconds: 3));
      
      setState(() {
        isBackendConnected = response.statusCode == 200;
      });
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
    setState(() {
      isProcessingML = true;
      feedback = 'Analyzing with ML model...';
      showFeedback = true;
    });

    try {
      // Extract pressure points and strokes from canvas
      final strokesData = canvasKey.currentState?.extractStrokes() ?? [];
      final pressureData = canvasKey.currentState?.getPressurePoints() ?? [];

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/recognize-handwriting'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'character': currentCharacter,
          'strokes': strokesData,
          'pressurePoints': pressureData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          mlConfidenceScore = (result['confidence'] ?? 0.0).toDouble();
          mlFeedback = result;
          isProcessingML = false;

          feedback = _generateMLFeedback(result);
          showFeedback = true;
        });
      } else {
        _showError('Model analysis failed');
      }
    } catch (e) {
      setState(() {
        isProcessingML = false;
        isBackendConnected = false;
      });
      _showBackendNotConnectedMessage();
      debugPrint('Error sending to ML model: $e');
    }
  }

  String _generateMLFeedback(Map<String, dynamic> result) {
    double confidence = (result['confidence'] ?? 0.0).toDouble();
    List<dynamic> suggestions = result['suggestions'] ?? [];

    String feedbackText = '';

    if (confidence >= 0.85) {
      feedbackText = '✅ Excellent! Your $currentCharacter looks perfect! (${(confidence * 100).toStringAsFixed(0)}% match)';
    } else if (confidence >= 0.70) {
      feedbackText = '👍 Good! Your $currentCharacter is recognizable. (${(confidence * 100).toStringAsFixed(0)}% match)';
    } else if (confidence >= 0.50) {
      feedbackText = '⚠️ Your $currentCharacter needs work. (${(confidence * 100).toStringAsFixed(0)}% match)';
    } else {
      feedbackText = '❌ That doesn\'t look like $currentCharacter. (${(confidence * 100).toStringAsFixed(0)}% match)';
    }

    if (suggestions.isNotEmpty) {
      feedbackText += '\n\nSuggestions:\n';
      for (var i = 0; i < suggestions.length && i < 3; i++) {
        feedbackText += '• ${suggestions[i]}\n';
      }
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
          if (showFeedback) _buildFeedback(),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final isError = feedback.contains('❌') || feedback.contains('Error');
    final isWarning = feedback.contains('⚠️');
    final isGood = feedback.contains('✅');

    Color bgColor;
    if (isError) {
      bgColor = Colors.red.shade50;
    } else if (isWarning) {
      bgColor = Colors.orange.shade50;
    } else if (isGood) {
      bgColor = Colors.green.shade50;
    } else {
      bgColor = Colors.blue.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Text(
        feedback,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}