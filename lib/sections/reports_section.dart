import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import '../utils/report_service.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';

class ReportsSection extends StatefulWidget {
  final String? childIdContext;
  
  const ReportsSection({super.key, this.childIdContext});

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  List<Child> childrenList = [];
  Child? selectedChild;
  ChildReport? currentReport;
  bool isLoading = true;
  String? errorMessage;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      userId = await Config.getUserId();
      if (userId == null) {
        setState(() {
          errorMessage = 'User not authenticated. Please login again.';
          isLoading = false;
        });
        return;
      }

      // Load children
      await _loadChildren();
      
      // If childIdContext provided (navigated from children page), select that child
      if (widget.childIdContext != null && childrenList.isNotEmpty) {
        final contextChild = childrenList.firstWhere(
          (c) => c.childId == widget.childIdContext,
          orElse: () => childrenList.first,
        );
        setState(() => selectedChild = contextChild);
        await _loadReport(contextChild.childId);
      } else if (childrenList.isNotEmpty) {
        setState(() => selectedChild = childrenList.first);
        await _loadReport(childrenList.first.childId);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadChildren() async {
    try {
      if (userId == null) return;
      
      final children = await ChildService.getChildren(userId: userId!);
      setState(() {
        childrenList = children;
        errorMessage = null;
      });
      
      debugPrint('✅ Loaded ${children.length} children');
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading children: $e';
      });
      debugPrint('❌ Error loading children: $e');
    }
  }

  Future<void> _loadReport(String childId) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Find child info
      final child = childrenList.firstWhere((c) => c.childId == childId);
      
      // Fetch report with child context
      final report = await ReportService.getChildReport(
        childId,
        childName: child.name,
        childAge: child.age,
      );

      setState(() {
        currentReport = report;
        isLoading = false;
        
        if (report == null) {
          errorMessage = 'No assessments available for ${child.name}. Complete a handwriting assessment to generate reports.';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading report: $e';
        isLoading = false;
      });
      debugPrint('❌ Error loading report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Reports'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Selection Dropdown - only show if not from children page
            if (childrenList.isNotEmpty && widget.childIdContext == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Select Child:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<Child>(
                        value: selectedChild,
                        isExpanded: true,
                        items: childrenList.map((child) {
                          return DropdownMenuItem<Child>(
                            value: child,
                            child: Text(child.name),
                          );
                        }).toList(),
                      onChanged: (child) {
                        if (child != null && child.childId != selectedChild?.childId) {
                          setState(() => selectedChild = child);
                          _loadReport(child.childId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Loading State
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading report...'),
                  ],
                ),
              ),
            )
          // Error State
          else if (errorMessage != null && currentReport == null)
            _buildEmptyState(context, theme)
          // Report Content
          else if (currentReport != null)
            _buildReportContent(context, theme, currentReport!)
          // No children
          else if (childrenList.isEmpty && !isLoading)
            _buildNoChildrenState(context, theme),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Assessments Available',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Complete a handwriting assessment to generate reports',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChildrenState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Children Found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a child profile from the Children section to view reports',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ThemeData theme, ChildReport report) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with child info
          _buildHeader(theme, report),
          const SizedBox(height: 24),

          // Assessment Components & Scores
          _buildAssessmentSection(theme, report),
          const SizedBox(height: 24),

          // Visual Analytics
          if (report.analysisScores.isNotEmpty) ...[
            _buildVisualAnalyticsSection(theme, report),
            const SizedBox(height: 24),
          ],

          // Recommendations
          _buildRecommendationsSection(theme, report),
          const SizedBox(height: 24),

          // Next Session Goal
          _buildNextSessionGoal(theme, report),
          const SizedBox(height: 24),

          // (Export buttons removed)
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ChildReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.orange,
            child: Text(
              report.childName.isNotEmpty ? report.childName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.childName,
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                'Age ${report.age ?? 'N/A'}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                'Assessment Date: ${_formatDate(report.generatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentSection(ThemeData theme, ChildReport report) {
    final components = _getAssessmentComponents(report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASSESSMENT COMPONENTS & SCORES',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Component')),
              DataColumn(label: Text('Score (0-2)')),
              DataColumn(label: Text('Notes')),
            ],
            rows: components.map((comp) {
              return DataRow(
                cells: [
                  DataCell(Text(comp['name'] as String)),
                  DataCell(
                    Text(
                      comp['score'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: comp['isAssessed'] == true
                            ? Colors.orange.shade700
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        comp['notes'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAnalyticsSection(ThemeData theme, ChildReport report) {
    final trend = ReportService.getProgressTrend(report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VISUAL ANALYTICS',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChartCard(
                'Pressure Graph',
                SizedBox(
                  height: 150,
                  child: _buildLineChart(trend, 'pressure', Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChartCard(
                'Progress Chart',
                SizedBox(
                  height: 150,
                  child: _buildLineChart(trend, 'overall', Colors.green),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          chart,
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<Map<String, dynamic>> trend,
    String key,
    Color color,
  ) {
    if (trend.isEmpty) {
      return Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey.shade400)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      final value = (trend[i][key] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme, ChildReport report) {
    final recommendations = _getRecommendations(report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THERAPIST RECOMMENDATIONS',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => _buildRecommendationItem(rec)),
      ],
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSessionGoal(ThemeData theme, ChildReport report) {
    final goal = _getNextSessionGoal(report);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT SESSION GOAL',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  // Export buttons removed as per UX request.

  List<Map<String, dynamic>> _getAssessmentComponents(ChildReport report) {
    final scores = report.analysisScores;
    final hasData = scores.isNotEmpty;

    // If no assessment data is available, show 'Take up a test' as the score
    const noDataLabel = 'Take up a test';

    List<Map<String, dynamic>> components = [
      {
        'name': 'Pressure',
        'score': report.pressureRank.toString(),
        'notes': 'Grip and pressure consistency',
        'isAssessed': true,
      },
      {
        'name': 'Letter Formation',
        'score': hasData ? ReportService.convertPercentageToScale(report.averageFormation).toString() : '0',
        'notes': 'Accuracy of letter shapes',
        'isAssessed': hasData,
      },
      {
        'name': 'Spacing',
        'score': report.averageSpacing.toString(),
        'notes': 'Letter and word spacing',
        'isAssessed': true,
      },
      {
        'name': 'Accuracy',
        'score': report.accuracyRank.toString(),
        'notes': 'Overall writing accuracy',
        'isAssessed': hasData,
      },
      // New additional rows requested: Pre writing shapes and Sentence writing (word formation)
      {
        'name': 'Pre writing Shapes',
        'score': hasData ? ReportService.convertPercentageToScale(report.averageFormation) : noDataLabel,
        'notes': 'Pre-writing shape recognition and tracing',
        'isAssessed': hasData,
      },
      {
        'name': 'Sentence Writing - Word Formation',
        'score': hasData ? ReportService.convertPercentageToScale(report.overallAverage) : noDataLabel,
        'notes': 'Word formation and sentence-level structure',
        'isAssessed': hasData,
      },
    ];

    return components;
  }

  List<String> _getRecommendations(ChildReport report) {
    final scores = report.analysisScores;
    if (scores.isEmpty) return [];

    List<String> recommendations = [];

    if (report.pressureRank < 1) {
      recommendations.add('Focus on pressure control exercises');
    }
    if (report.averageFormation < 50) {
      recommendations.add('Practice letter formation drills');
    }
    if (report.averageSpacing < 1) {
      recommendations.add('Work on spacing consistency');
    }
    if (report.accuracyRank < 1) {
      recommendations.add('Daily 10-minute practice on lined sheets');
    }

    // Default recommendations
    if (recommendations.isEmpty) {
      recommendations = [
        'Continue daily handwriting practice',
        'Focus on letter formation accuracy',
        'Practice spacing and alignment',
        'Build writing endurance gradually',
      ];
    }

    return recommendations;
  }

  String _getNextSessionGoal(ChildReport report) {
    final scores = report.analysisScores;
    if (scores.isEmpty) return 'Complete your first handwriting assessment';

    if (report.averageFormation < 60) {
      return 'Improve letter formation consistency and accuracy';
    } else if (report.averageSpacing < 2) {
      return 'Focus on maintaining consistent spacing between letters';
    } else if (report.pressureRank < 2) {
      return 'Work on developing consistent pressure control';
    } else if (report.accuracyRank < 2) {
      return 'Improve overall accuracy in handwriting';
    }

    return 'Continue improving overall handwriting quality and consistency';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
