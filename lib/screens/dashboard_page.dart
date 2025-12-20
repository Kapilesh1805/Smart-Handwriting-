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

class DashboardPage extends StatefulWidget {
  final List<AppointmentItem> appointments;
  final UserProfile? user;
  const DashboardPage({super.key, this.appointments = const [], this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedSection = 'Dashboard';

  // TODO: API INTEGRATION - Add user profile state variable
  @override
  void initState() {
    super.initState();
    // TODO: API INTEGRATION - Fetch user profile when dashboard loads
    // _fetchUserProfile();
  }

  // TODO: API INTEGRATION - Add this method to fetch user profile from backend
  // Future<void> _fetchUserProfile() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('YOUR_BACKEND_URL/api/user/profile'),
  //       headers: {
  //         'Authorization': 'Bearer YOUR_API_KEY',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (mounted) {
  //         setState(() {
  //           _currentUser = UserProfile(
  //             name: data['name'] ?? 'User',
  //             occupation: data['occupation'] ?? 'Therapist',
  //           );
  //         });
  //       }
  //     } else {
  //       print('Failed to load user profile: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching user profile: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Could not load profile: $e')),
  //       );
  //     }
  //   }
  // }

  // UserProfile? _currentUser;

  void _onSelectSection(String label) {
    setState(() {
      _selectedSection = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ==================== GET THEME ====================
    final theme = Theme.of(context);
    // ==================================================

    return Scaffold(
      // ==================== USE THEME BACKGROUND ====================
      backgroundColor: theme.scaffoldBackgroundColor,
      // ==================================================
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
                  const TopBar(),
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
                                ? const ChildrensMain()
                                : _selectedSection == 'Pre writing'
                                ? const PreWritingSection()
                                : _selectedSection == 'Sentence Writing'
                                ? const SentenceSection()
                                : _selectedSection == 'Settings'
                                ? const SettingsSection()
                                : const DashboardSection(),
                          ),
                          const SizedBox(width: 24.0),
                          Expanded(
                            flex: 1,
                            child: RightPanel(
                              appointments: widget.appointments,
                              // TODO: API INTEGRATION - Replace widget.user with _currentUser
                              // user: _currentUser, // USE THIS INSTEAD
                              user: widget
                                  .user, // ← REMOVE THIS LINE after API integration
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