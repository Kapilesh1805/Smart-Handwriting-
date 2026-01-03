import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import '../utils/report_service.dart';
import '../models/child_profile.dart';
import '../utils/child_service.dart';

class ReportsSection extends StatefulWidget {
  const ReportsSection({Key? key}) : super(key: key);

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  List<ChildProfile> childrenList = [];
  String? selectedChildId;
  ChildReport? currentReport;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => isLoading = true);
    try {
      final children = await ChildService.getAllChildren();
      setState(() {
        childrenList = children;
        if (children.isNotEmpty) {
          selectedChildId = children.first.id;
          _loadReport();
        }
      });
    } catch (e) {
      setState(() => errorMessage = 'Error loading children: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadReport() async {
    if (selectedChildId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final report = await ReportService.getChildReport(selectedChildId!);
      setState(() {
        currentReport = report;
        if (report == null) {
          errorMessage = 'No data available for this child yet.';
        }
      });
    } catch (e) {
      setState(() => errorMessage = 'Error loading report: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Child Selection Dropdown
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
                          setState(() => selectedChildId = value);
                          _loadReport();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Loading or Error State
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(32),
                child: const CircularProgressIndicator(),
              )
            else if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else if (currentReport != null)
              _buildReportContent(currentReport!)
            else
              Container(
                padding: const EdgeInsets.all(32),
                child: const Text(
                  'No report data available',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ChildReport report) {
    final summary = ReportService.getPerformanceSummary(report);
    final trend = ReportService.getProgressTrend(report);

    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildSummaryCard(
                    'Overall Score',
                    '${summary['overall_average'].toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    'Sessions',
                    '${summary['total_sessions']}',
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    'Completion',
                    '${summary['completion_percentage'].toStringAsFixed(0)}%',
                    Colors.orange,
                  ),
                  _buildSummaryCard(
                    'Letters Practiced',
                    '${summary['letters_practiced']}/26',
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overall Score Over Time
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Score Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _buildLineChart(
                  trend,
                  'overall',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Metric Breakdown (Pressure, Spacing, Formation)
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metric Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: _buildBarChart(report),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pressure Score Trend
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pressure Consistency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: _buildLineChart(
                  trend,
                  'pressure',
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top Performing Letters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⭐ Top Performing Letters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: (summary['top_letters'] as List<String>).map((letter) {
                  return Chip(
                    label: Text(letter),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Letters Needing Help
        if ((summary['letters_needing_help'] as List<String>).isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📚 Letters Needing Practice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: (summary['letters_needing_help'] as List<String>)
                      .map((letter) {
                    return Chip(
                      label: Text(letter),
                      backgroundColor: Colors.orange,
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Export and Share Buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportReport(report),
                  icon: const Icon(Icons.download),
                  label: const Text('Export PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _emailReport(report),
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
      return const Center(child: Text('No data available'));
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
          horizontalInterval: 20,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ChildReport report) {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: report.averagePressure,
                color: Colors.red,
                width: 16,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: report.averageSpacing,
                color: Colors.blue,
                width: 16,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: report.averageFormation,
                color: Colors.green,
                width: 16,
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Pressure', 'Spacing', 'Formation'];
                final idx = value.toInt();
                return Text(titles[idx]);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
        ),
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Future<void> _exportReport(ChildReport report) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting PDF...')),
    );

    final success = await ReportService.exportReportAsPdf(report.childId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'PDF exported successfully!' : 'Export failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _emailReport(ChildReport report) async {
    showDialog(
      context: context,
      builder: (ctx) => _buildEmailDialog(report),
    );
  }

  Widget _buildEmailDialog(ChildReport report) {
    final emailController = TextEditingController();

    return AlertDialog(
      title: const Text('Email Report'),
      content: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Parent email',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sending email...')),
            );

            final success = await ReportService.emailReportToParent(
              report.childId,
              emailController.text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Email sent successfully!' : 'Failed to send email'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
