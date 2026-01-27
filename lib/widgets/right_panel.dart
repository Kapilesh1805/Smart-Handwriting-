import 'package:flutter/material.dart';
import '../models/app_models.dart';
import 'common_widgets.dart';

class RightPanel extends StatefulWidget {
  final List<AppointmentItem> appointments;
  final UserProfile? user;
  const RightPanel({super.key, required this.appointments, required this.user});

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  String _formatMonth(int month) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return months[month - 1];
  }

  String _formatWeekday(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Get today's date and the next date
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    return ListView(
      children: [
        CustomCard(
          child: Row(
            children: [
              const CircleAvatar(radius: 20.0, child: Icon(Icons.person)),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  widget.user != null ? '${widget.user!.name}\n${widget.user!.occupation}' : '—\n—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: ScheduleCard(
                      year: today.year.toString(),
                      month: _formatMonth(today.month),
                      day: today.day.toString().padLeft(2, '0'),
                      weekday: _formatWeekday(today.weekday),
                      dark: true,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ScheduleCard(
                      year: tomorrow.year.toString(),
                      month: _formatMonth(tomorrow.month),
                      day: tomorrow.day.toString().padLeft(2, '0'),
                      weekday: _formatWeekday(tomorrow.weekday),
                      dark: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Dr. Alfredo Torres'),
                subtitle: Text(
                  'You automatically lose the chances you don\'t take.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}