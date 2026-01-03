import 'package:flutter/material.dart';
import '../widgets/appointment_widgets.dart';
import '../services/appointment_service.dart';

class AppointmentSection extends StatefulWidget {
  const AppointmentSection({super.key});

  @override
  State<AppointmentSection> createState() => _AppointmentSectionState();
}

class _AppointmentSectionState extends State<AppointmentSection> {
  DateTime selectedDay = DateTime.now();
  Map<int, SlotData> appointments = {};
  List<Appointment> _allAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final allAppointments = await AppointmentService.getAllAppointments();
      
      if (mounted) {
        setState(() {
          _allAppointments = allAppointments;
          _loadAppointmentsForDay(selectedDay);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void _loadAppointmentsForDay(DateTime day) {
    appointments.clear();
    final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    
    for (var apt in _allAppointments) {
      if (apt.date == dayStr) {
        final timeParts = apt.time.split(':');
        final hour = int.tryParse(timeParts[0]) ?? 0;
        
        final Color statusColor = apt.status == 'completed'
            ? const Color(0xFF22C55E)
            : apt.status == 'pending'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
        
        appointments[hour] = SlotData(apt.childName, statusColor);
      }
    }
  }

  String _formatHour12(int hour24) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour = hour24 % 12;
    if (hour == 0) hour = 12;
    final label = hour.toString().padLeft(2, '0');
    return '$label:00 $period';
  }

  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    final childNameCtrl = TextEditingController();
    final therapistNameCtrl = TextEditingController();
    final sessionTypeCtrl = TextEditingController();
    String selectedHour = '09';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Schedule Session'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: childNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Child Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: therapistNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Therapist Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: sessionTypeCtrl.text.isEmpty ? 'Writing' : sessionTypeCtrl.text,
                    decoration: InputDecoration(
                      labelText: 'Session Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ['Writing', 'Pre-Writing', 'Sentence', 'General']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) sessionTypeCtrl.text = value;
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedHour,
                    decoration: InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: List.generate(24, (i) {
                      final hour = i.toString().padLeft(2, '0');
                      return DropdownMenuItem(value: hour, child: Text('$hour:00'));
                    }),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedHour = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isSubmitting = true);

                        try {
                          final dayStr = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                          
                          await AppointmentService.addAppointment(
                            childName: childNameCtrl.text,
                            therapistName: therapistNameCtrl.text,
                            sessionType: sessionTypeCtrl.text,
                            date: dayStr,
                            time: '$selectedHour:00',
                          );

                          Navigator.pop(ctx);
                          await _fetchAppointments();
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Session scheduled for ${childNameCtrl.text}')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                            );
                          }
                        }
                      }
                    },
              child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error saving appointment: $e')),
  //       );
  //     }
  //   }
  // }

  //       headers: {
  //         'Authorization': 'Bearer YOUR_API_KEY',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       if (mounted) {
  //         setState(() {
  //           appointments.remove(hour);
  //         });
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Appointment deleted')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error deleting appointment: $e')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final DateTime start = selectedDay.subtract(
      Duration(days: selectedDay.weekday),
    );
    final dates = List<DateTime>.generate(
      6,
      (i) => start.add(Duration(days: i + 1)),
    );
    return ListView(
      children: [
        Row(
          children: [
            Text(
              _formatMonthYear(selectedDay),
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 16.0),
            IconPill(icon: Icons.chevron_left, onTap: () => _shiftDays(-7)),
            const SizedBox(width: 8.0),
            IconPill(icon: Icons.chevron_right, onTap: () => _shiftDays(7)),
            const Spacer(),
            RoundAction(
              icon: Icons.add,
              label: 'Add Session',
              onTap: _showAddAppointmentDialog,
            ),
            const SizedBox(width: 16.0),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: dates
              .map(
                (d) => Expanded(
                  child: DateChip(
                    date: d,
                    isSelected: _isSameDay(d, selectedDay),
                    onTap: () => setState(() => selectedDay = d),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6.0),
        const Text(
          'Work in Progress',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.0),
        ),
        const SizedBox(height: 6.0),
        SizedBox(height: 340.0, child: _buildCompactTimeline()),
        const SizedBox(height: 8.0),
        const Legend(color: Color(0xFF22C55E), label: 'Completed'),
        const Legend(color: Color(0xFFF59E0B), label: 'Pending'),
        const Legend(color: Color(0xFFEF4444), label: 'Missed'),
      ],
    );
  }

  Widget _buildCompactTimeline() {
    final Map<int, SlotData> data = appointments;
    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, i) {
        final labelHour = _formatHour12(i);
        final slot = data[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100.0,
                child: Text(
                  labelHour,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              if (slot != null) ...[
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: slot.color, width: 2.0),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 14.0,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: InkWell(
                    onTap: () => _editAppointment(context, i, slot),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: slot.color,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              slot.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit,
                            size: 16.0,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _editAppointment(BuildContext context, int hour, SlotData slot) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: slot.label);
    String selectedStatus = slot.color == const Color(0xFF22C55E)
        ? 'Completed'
        : slot.color == const Color(0xFFF59E0B)
        ? 'Pending'
        : 'Missed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Appointment - ${_formatHour12(hour)}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Missed', child: Text('Missed')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedStatus = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (mounted) {
                  setState(() {
                    appointments.remove(hour);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment deleted')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameCtrl.text;
                  Navigator.of(ctx).pop();
                  final Color statusColor = selectedStatus == 'Completed'
                      ? const Color(0xFF22C55E)
                      : selectedStatus == 'Pending'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);

                  if (mounted) {
                    setState(() {
                      appointments[hour] = SlotData(name, statusColor);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment updated')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _shiftDays(int delta) =>
      setState(() => selectedDay = selectedDay.add(Duration(days: delta)));

  String _formatMonthYear(DateTime d) {
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
    return '${months[d.month - 1]} ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}