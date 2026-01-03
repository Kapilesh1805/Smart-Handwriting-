import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';
import '../widgets/right_panel.dart';
import '../sections/dashboard_section.dart';
import '../sections/appointment_section.dart';
import '../sections/writing_interface_section.dart';
import '../sections/childrens_main.dart';
import '../sections/assessment_report_section.dart';
import '../sections/pre_writing_section.dart';
import '../sections/settings_section.dart';
import '../sections/sentence_section.dart';
import '../services/child_service.dart';
import '../config/api_config.dart';

class DashboardPage extends StatefulWidget {
  final List<AppointmentItem> appointments;
  final UserProfile? user;
  const DashboardPage({super.key, this.appointments = const [], this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedSection = 'Dashboard';
  
  // State variables for API data
  UserProfile? _currentUser;
  List<Child> _children = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  /// Initialize dashboard by loading user profile and children list
  Future<void> _initializeDashboard() async {
    try {
      // Get user ID from SharedPreferences
      _userId = await Config.getUserId();
      _userName = await Config.getUserName();
      
      if (_userId == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Fetch children for this user
      await _fetchChildren();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch children list from backend
  Future<void> _fetchChildren() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final children = await ChildService.getChildren(userId: _userId!);
      
      if (mounted) {
        setState(() {
          _children = children;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// Refresh children list (called after add/edit/delete operations)
  Future<void> _refreshChildren() async {
    await _fetchChildren();
  }

  void _onSelectSection(String label) {
    setState(() {
      _selectedSection = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading indicator while initializing
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if failed to load
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeDashboard();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Sidebar(
              selectedLabel: _selectedSection,
              onSelect: _onSelectSection,
            ),
            Expanded(
              child: Column(
                children: [
                  TopBar(userName: _userName),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _selectedSection == 'Appointment'
                                ? const AppointmentSection()
                                : _selectedSection == 'Writing Interface'
                                    ? const WritingInterfaceSection()
                                    : _selectedSection == 'Report'
                                        ? const AssessmentReportSection(
                                            childId: 'child_123',
                                          )
                                        : _selectedSection == 'Childrens'
                                                ? ChildrensMain(
                                                    children: _children,
                                                    onRefresh: _refreshChildren,
                                                  )
                                                : _selectedSection == 'Pre writing'
                                                    ? const PreWritingSection()
                                                    : _selectedSection == 'Sentence Writing'
                                                        ? const SentenceSection()
                                                        : _selectedSection == 'Settings'
                                                            ? const SettingsSection()
                                                            : DashboardSection(
                                                                children: _children,
                                                                onRefresh: _refreshChildren,
                                                              ),
                          ),
                          const SizedBox(width: 24.0),
                          Expanded(
                            flex: 1,
                            child: RightPanel(
                              appointments: widget.appointments,
                              user: _currentUser ?? widget.user,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}