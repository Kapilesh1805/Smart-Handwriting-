import 'package:flutter/material.dart';
import '../models/assessment_report.dart';
import '../models/child_profile.dart';
import '../utils/assessment_service.dart';
import '../utils/child_service.dart';

class AssessmentReportSection extends StatefulWidget {
  final String? childId;

  const AssessmentReportSection({
    super.key,
    this.childId,
  });

  @override
  State<AssessmentReportSection> createState() => _AssessmentReportSectionState();
}

class _AssessmentReportSectionState extends State<AssessmentReportSection> {
  AssessmentReport? _report;
  bool _isLoading = true;
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  String? selectedChildName;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await ChildService.fetchChildren();
      if (mounted) {
        setState(() {
          childrenList = children;
          if (widget.childId != null) {
            selectedChildId = widget.childId;
            try {
              final child = children.firstWhere((c) => c.id == widget.childId);
              selectedChildName = child.name;
            } catch (e) {
              if (children.isNotEmpty) {
                selectedChildId = children.first.id;
                selectedChildName = children.first.name;
              }
            }
          } else if (children.isNotEmpty) {
            selectedChildId = children.first.id;
            selectedChildName = children.first.name;
          }
        });
      }
      if (selectedChildId != null) {
        await _loadAssessmentReport(selectedChildId!);
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssessmentReport(String childId) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    // TODO: API INTEGRATION - This will fetch from backend
    final report = await AssessmentService.fetchAssessmentReport(childId);
    
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D3748)),
        ),
      );
    }

    if (_report == null || childrenList.isEmpty) {
      return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (childrenList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                            _loadAssessmentReport(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No assessment report available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (selectedChildId != null)
                    ElevatedButton.icon(
                      onPressed: () => _loadAssessmentReport(selectedChildId!),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3748),
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          tooltip: 'Back to Children',
        ),
        title: const Text(
          'Assessment Report',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child selection dropdown
            if (childrenList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
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
                            _loadAssessmentReport(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Header with child info and title
            _buildHeader(),
            const SizedBox(height: 24),

            // Main content
            _buildAssessmentComponents(),
            const SizedBox(height: 24),
            _buildVisualAnalytics(),

            const SizedBox(height: 24),

            // Bottom section - Recommendations and next goal
            _buildRecommendationsSection(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Child avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.person, size: 36, color: Colors.orange),
              ),
              const SizedBox(width: 16),

              // Child info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _report!.childName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age ${_report!.age}  •  Grade ${_report!.grade}  •  ${_report!.date}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Title on separate line
          const Text(
            'HANDWRITING ASSESSMENT REPORT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentComponents() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Text(
              'ASSESSMENT COMPONENTS & SCORES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Table headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Component',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Observation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Component rows
          ...(_report!.componentScores.map((component) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      component.component,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        '${component.score}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      component.observation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList()),

          // Grade section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: _buildGradeDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDisplay() {
    Color gradeColor = _getGradeColor(_report!.overallGrade);
    int starCount = _getStarCount(_report!.gradePercentage);

    return Column(
      children: [
        Text(
          'GRADE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Stars
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < starCount ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Grade letter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.1),
                border: Border.all(color: gradeColor, width: 2.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _report!.overallGrade,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_report!.gradePercentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAnalytics() {
    return Column(
      children: [
        // Baseline Tracking (Top)
        _buildAnalyticsCard(
          title: 'Baseline Tracking',
          subtitle: '',
          child: _buildBarChart(
            _report!.visualAnalytics.baselineTracking,
            Colors.orange,
          ),
        ),
        const SizedBox(height: 16),

        // Progress Chart (Bottom)
        _buildAnalyticsCard(
          title: 'Progress Chart',
          subtitle: 'Last 4 sessions',
          child: _buildProgressChart(
            _report!.visualAnalytics.progressChart,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, Color color) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          // Calculate bar height (max 165 pixels to leave space for text)
          final barHeight = (entry.value / maxValue) * 165;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressChart(Map<String, double> data, Color color) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: ProgressLineChartPainter(data: data, color: color),
        child: Container(),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THERAPIST RECOMMENDATIONS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Improvements column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'WHAT = ↑ ↑ ↑ ↑',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_report!.recommendations.improvements.map((improvement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                improvement,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // Areas to focus column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.priority_high, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'AREAS TO FOCUS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_report!.recommendations.areasToFocus.map((area) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                area,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Next Session Goal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flag, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'NEXT SESSION GOAL:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _report!.nextSessionGoal,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
        return Colors.green;
      case 'B':
      case 'B+':
        return Colors.orange;
      case 'C':
      case 'C+':
        return Colors.yellow.shade700;
      default:
        return Colors.red;
    }
  }

  int _getStarCount(double percentage) {
    if (percentage >= 90) return 5;
    if (percentage >= 80) return 4;
    if (percentage >= 70) return 3;
    if (percentage >= 60) return 2;
    return 1;
  }
}

// Custom painter for progress chart
class ProgressLineChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color color;

  ProgressLineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final values = data.values.toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = (size.width / (values.length - 1)) * i;
      final y = size.height - ((values[i] - minValue) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      points.add(Offset(x, y));
    }

    canvas.drawPath(path, paint);
    
    for (var point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}