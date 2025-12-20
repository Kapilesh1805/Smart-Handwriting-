import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 220.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE3E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                const double cardHeight = 220.0;
                final double targetWidth = maxWidth * 0.60;
                final double width = targetWidth.clamp(280.0, 720.0);
                final double height = (cardHeight * 0.9).clamp(
                  180.0,
                  cardHeight,
                );
                return SizedBox(
                  width: width,
                  height: height,
                  child: Image.asset(
                    'assets/images/floe_banner.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FC),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE3E8F0)),
                        ),
                        child: const Text(
                          'Image not found:\nassets/images/floe_banner.png',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        Row(
          children: [
            FeatureCard(
              title: 'Add new\nchild profile',
              icon: Icons.child_care,
              onTap: () => _showAddChildDialog(context),
            ),
            const SizedBox(width: 16.0),
            FeatureCard(
              title: 'Saved\nAssessments',
              icon: Icons.description_outlined,
              onTap: () => _showSavedAssessmentsDialog(context),
            ),
            const SizedBox(width: 16.0),
            FeatureCard(
              title: 'Generate\nreports',
              icon: Icons.insert_chart_outlined,
              onTap: () => _showGenerateReportsDialog(context),
            ),
            const SizedBox(width: 16.0),
            FeatureCard(
              title: 'Progress\nanalytics',
              icon: Icons.show_chart,
              onTap: () => _showProgressAnalyticsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddChildDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add new child profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Child name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop();
                  // TODO: API INTEGRATION - Save child profile to backend
                  // _saveChildProfileToBackend(nameCtrl.text, ageCtrl.text, notesCtrl.text);

                  // REMOVE THIS LINE AFTER API INTEGRATION ↓
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${nameCtrl.text}')),
                  );
                  // REMOVE THIS LINE AFTER API INTEGRATION ↑
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      ageCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showSavedAssessmentsDialog(BuildContext context) {
    // TODO: API INTEGRATION - Fetch saved assessments before showing dialog
    // _fetchSavedAssessments(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved Assessments'),
        // REPLACE THIS CONTENT AFTER API INTEGRATION ↓
        content: const Text('This will list saved assessments from backend.'),
        // WITH: ListView showing fetched data
        // content: SizedBox(
        //   width: double.maxFinite,
        //   child: ListView.builder(
        //     shrinkWrap: true,
        //     itemCount: assessments.length,
        //     itemBuilder: (context, index) {
        //       return ListTile(
        //         title: Text(assessments[index].name),
        //         subtitle: Text(assessments[index].date),
        //       );
        //     },
        //   ),
        // ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGenerateReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate reports'),
        content: const Text(
          'Choose parameters and generate downloadable reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          // TODO: API INTEGRATION - Add Generate button
          // ElevatedButton(
          //   onPressed: () => _generateReportFromBackend(),
          //   child: const Text('Generate'),
          // ),
        ],
      ),
    );
  }

  void _showProgressAnalyticsDialog(BuildContext context) {
    // TODO: API INTEGRATION - Fetch analytics data
    // _fetchProgressAnalytics(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Progress analytics'),
        // REPLACE THIS CONTENT AFTER API INTEGRATION ↓
        content: const Text('Analytics and charts will appear here.'),
        // WITH: Charts showing fetched data
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}