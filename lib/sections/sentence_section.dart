import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sentence_model.dart';
import '../models/child_profile.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';
import '../widgets/unified_writing_canvas.dart';

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
  // Child selection
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  String? selectedChildName;
  
  // Sentence data
  List<Sentence> availableSentences = [];
  Sentence? currentSentence;
  String selectedDifficulty = 'easy';
  bool showSentence = true;

  // Canvas reference for unified writing canvas
  final GlobalKey<UnifiedWritingCanvasState> canvasKey = GlobalKey<UnifiedWritingCanvasState>();

  // Canvas settings
  Color selectedColor = Colors.blue;
  double strokeWidth = 5.0;

  // Analysis
  SentenceAnalysisResult? analysisResult;
  List<LetterVerification>? letterVerifications;

  // Status
  bool isBackendConnected = false;
  bool isProcessing = false;
  bool showAnalysis = false;
  String feedbackMessage = '';
  bool showFeedback = false;

  @override
  void initState() {
    super.initState();
    _initializeDummySentences();
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
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:8000/api/health'))
          .timeout(const Duration(seconds: 3));

      setState(() {
        isBackendConnected = response.statusCode == 200;
      });
      
      // Load real sentences from backend if connected
      if (isBackendConnected) {
        _loadSentences();
      }
    } catch (e) {
      setState(() {
        isBackendConnected = false;
      });
      debugPrint('Backend not connected: $e');
    }
  }

  void _initializeDummySentences() {
    setState(() {
      availableSentences = [
        Sentence(
          id: 'dummy1',
          text: 'The quick brown fox jumps over the lazy dog.',
          difficulty: 'easy',
          language: 'en',
          wordCount: 9,
        ),
        Sentence(
          id: 'dummy2',
          text: 'She walks in the morning to stay healthy.',
          difficulty: 'easy',
          language: 'en',
          wordCount: 8,
        ),
        Sentence(
          id: 'dummy3',
          text: 'He enjoys reading books in the library every day.',
          difficulty: 'medium',
          language: 'en',
          wordCount: 9,
        ),
        Sentence(
          id: 'dummy4',
          text: 'Learning new languages opens doors to different cultures.',
          difficulty: 'medium',
          language: 'en',
          wordCount: 8,
        ),
        Sentence(
          id: 'dummy5',
          text: 'The ambitious project required meticulous planning and dedication.',
          difficulty: 'hard',
          language: 'en',
          wordCount: 8,
        ),
      ];
      currentSentence = availableSentences[0];
    });
  }

  Future<void> _loadSentences() async {
    if (!isBackendConnected) return;

    try {
      final response = await http
          .get(Uri.parse(
              'http://localhost:8000/api/sentences?difficulty=$selectedDifficulty'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableSentences = (data['sentences'] as List)
              .map((s) => Sentence.fromJson(s as Map<String, dynamic>))
              .toList();
          if (availableSentences.isNotEmpty) {
            currentSentence = availableSentences[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading sentences from backend: $e');
      // Keep dummy sentences if backend fails
    }
  }

  void _selectSentence(Sentence sentence) {
    canvasKey.currentState?.clearCanvas();
    setState(() {
      currentSentence = sentence;
      analysisResult = null;
      letterVerifications = null;
      showAnalysis = false;
      feedbackMessage = '';
      showFeedback = false;
    });
  }

  void _nextSentence() {
    if (availableSentences.isEmpty) return;
    
    final currentIndex = availableSentences.indexWhere((s) => s.id == currentSentence?.id);
    if (currentIndex < availableSentences.length - 1) {
      _selectSentence(availableSentences[currentIndex + 1]);
    }
  }

  void _previousSentence() {
    if (availableSentences.isEmpty) return;
    
    final currentIndex = availableSentences.indexWhere((s) => s.id == currentSentence?.id);
    if (currentIndex > 0) {
      _selectSentence(availableSentences[currentIndex - 1]);
    }
  }

  void _changeDifficulty(String difficulty) {
    setState(() {
      selectedDifficulty = difficulty;
    });
    _loadSentences();
  }

  void _clearCanvas() {
    canvasKey.currentState?.clearCanvas();
    setState(() {
      showAnalysis = false;
      analysisResult = null;
      feedbackMessage = '';
      showFeedback = false;
    });
  }

  void _undo() {
    canvasKey.currentState?.undoStroke();
  }

  Future<void> _checkSentenceWriting() async {
    if (currentSentence == null) {
      setState(() {
        feedbackMessage = 'Please select a sentence first!';
        showFeedback = true;
      });
      return;
    }

    final strokesData = canvasKey.currentState?.extractStrokes() ?? [];
    if (strokesData.isEmpty) {
      setState(() {
        feedbackMessage = 'Please write the sentence first!';
        showFeedback = true;
      });
      return;
    }

    if (!isBackendConnected) {
      _showBackendNotConnectedMessage();
      return;
    }

    setState(() {
      isProcessing = true;
      feedbackMessage = 'Analyzing your sentence...';
      showFeedback = true;
    });

    try {
      final strokes = strokesData;
      final pressure = canvasKey.currentState?.getPressurePoints() ?? [];

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/sentence-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sentence_text': currentSentence!.text,
          'drawing_strokes': strokes,
          'pressure_points': pressure,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          analysisResult = SentenceAnalysisResult.fromJson(result);
          letterVerifications = analysisResult!.letterVerifications;
          isProcessing = false;
          showAnalysis = true;
          feedbackMessage = '';
          showFeedback = false;
        });
      } else {
        _showError('Analysis failed. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        isBackendConnected = false;
      });
      _showBackendNotConnectedMessage();
      debugPrint('Error checking sentence: $e');
    }
  }

  void _showBackendNotConnectedMessage() {
    setState(() {
      feedbackMessage =
          '🔌 Backend not connected!\n\nPlease ensure the backend server is running at http://localhost:8000';
      showFeedback = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Backend unavailable - Analysis disabled'),
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
    return Material(
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

        // TOP: Header & Sentence Selection
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Title Row with Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.blue),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Go back',
                  ),
                  const Text(
                    'Sentence Writing',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBackendConnected ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isBackendConnected ? '✅ Connected' : '❌ Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isBackendConnected ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Difficulty Selection
                  Wrap(
                    spacing: 6,
                    children: ['easy', 'medium', 'hard'].map((diff) {
                      final isSelected = diff == selectedDifficulty;
                      return FilterChip(
                        label: Text(
                          diff.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _changeDifficulty(diff),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.blue.shade400,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Sentence Display with toggle and navigation arrows
              if (currentSentence != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Write This:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: () => setState(() => showSentence = !showSentence),
                            icon: Icon(showSentence ? Icons.visibility : Icons.visibility_off),
                            color: Colors.blue,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _previousSentence,
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.blue,
                            iconSize: 24,
                          ),
                          Expanded(
                            child: Text(
                              showSentence ? currentSentence!.text : '* * * * * * * * * * * *',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: _nextSentence,
                            icon: const Icon(Icons.arrow_forward),
                            color: Colors.blue,
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Sentence Carousel - Hidden (navigation via arrows)
              // if (availableSentences.isNotEmpty) ...[
              //   const SizedBox(height: 10),
              //   ... carousel code hidden ...
              // ],
            ],
          ),
        ),

        // MIDDLE: Full Canvas Area with Unified Canvas Widget
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: UnifiedWritingCanvas(
                    key: canvasKey,
                    onClear: () => setState(() => showAnalysis = false),
                    onUndo: () {},
                    canvasHeight: double.infinity,
                    drawingColor: selectedColor,
                    strokeWidth: strokeWidth,
                  ),
                ),
                const SizedBox(height: 12),
                // BOTTOM: Toolbar
                _buildToolbar(),
                if (showFeedback) ...[
                  const SizedBox(height: 8),
                  _buildErrorFeedback(),
                ]
              ],
            ),
          ),
        ),

        // Analysis Results (if any)
        if (showAnalysis && analysisResult != null) _buildAnalysisResults(),
      ],
    ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(Icons.edit, 'Draw', () {}, true),
          _buildToolButton(Icons.undo, 'Undo', _undo, false),
          _buildToolButton(Icons.delete, 'Clear', _clearCanvas, false),
          _buildToolButton(
            isProcessing ? Icons.hourglass_bottom : Icons.psychology,
            'Check',
            isProcessing ? () {} : _checkSentenceWriting,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange.shade600 : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.orange.shade600 : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorFeedback() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedbackMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
                height: 1.5,
              ),
            ),
          ),
          if (isProcessing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (analysisResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Results',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Overall Scores
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  'Overall Accuracy',
                  '${(analysisResult!.overallAccuracy * 100).toStringAsFixed(0)}%',
                  analysisResult!.overallAccuracy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreCard(
                  'Completion',
                  '${(analysisResult!.overallCompletion * 100).toStringAsFixed(0)}%',
                  analysisResult!.overallCompletion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Per-Letter Analysis
          _buildLetterByLetterAnalysis(),
          const SizedBox(height: 20),

          // Pressure Analysis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Pressure Analysis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  analysisResult!.pressureAnalysis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  '🎯 Control: ${analysisResult!.controlAnalysis}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Improvement Suggestions
          if (analysisResult!.improvementSuggestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Areas to Improve',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysisResult!.improvementSuggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• $suggestion',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    currentSentence = null;
                    analysisResult = null;
                    showAnalysis = false;
                    canvasKey.currentState?.clearCanvas();
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('New Sentence'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String score, double value) {
    final isGood = value >= 0.85;
    final isMedium = value >= 0.70;

    Color bgColor = isGood ? Colors.green.shade50 : (isMedium ? Colors.yellow.shade50 : Colors.red.shade50);
    Color borderColor = isGood ? Colors.green.shade300 : (isMedium ? Colors.yellow.shade300 : Colors.red.shade300);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGood ? Colors.green : (isMedium ? Colors.orange : Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterByLetterAnalysis() {
    if (letterVerifications == null || letterVerifications!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Per-Letter Analysis',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(letterVerifications!.length, (index) {
              final letter = letterVerifications![index];
              final isGood = letter.confidence >= 0.85;
              final isMedium = letter.confidence >= 0.70;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isGood ? Colors.green.shade50 : (isMedium ? Colors.yellow.shade50 : Colors.red.shade50),
                  border: Border.all(
                    color: isGood ? Colors.green.shade400 : (isMedium ? Colors.orange.shade400 : Colors.red.shade400),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      letter.expectedLetter == ' ' ? '[space]' : letter.expectedLetter,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${(letter.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGood ? Colors.green.shade700 : (isMedium ? Colors.orange.shade700 : Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}


