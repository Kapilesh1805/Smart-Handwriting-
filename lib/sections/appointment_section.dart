import 'package:flutter/material.dart';
import '../widgets/appointment_widgets.dart';

class AppointmentSection extends StatefulWidget {
  const AppointmentSection({super.key});

  @override
  State<AppointmentSection> createState() => _AppointmentSectionState();
}

class _AppointmentSectionState extends State<AppointmentSection> {
  DateTime selectedDay = DateTime.now();
  Map<int, SlotData> appointments = {};

  // TODO: API INTEGRATION - Add these imports at top of file
  // import 'dart:convert';
  // import 'package:http/http.dart' as http;

  @override
  void initState() {
    super.initState();
    // TODO: API INTEGRATION - Fetch appointments when page loads
    // _fetchAppointmentsFromBackend();
  }

  // TODO: API INTEGRATION - Add this method to fetch appointments
  // Future<void> _fetchAppointmentsFromBackend() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('YOUR_BACKEND_URL/api/appointments?date=${selectedDay.toIso8601String()}'),
  //       headers: {
  //         'Authorization': 'Bearer YOUR_API_KEY',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as List;
  //       if (mounted) {
  //         setState(() {
  //           appointments.clear();
  //           for (var item in data) {
  //             final hour = item['time'] as int;
  //             final name = item['name'] as String;
  //             final status = item['status'] as String;
  //
  //             final Color statusColor = status == 'Completed'
  //                 ? const Color(0xFF22C55E)
  //                 : status == 'Pending'
  //                 ? const Color(0xFFF59E0B)
  //                 : const Color(0xFFEF4444);
  //
  //             appointments[hour] = SlotData(name, statusColor);
  //           }
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error loading appointments: $e')),
  //       );
  //     }
  //   }
  // }

  // TODO: API INTEGRATION - Add this method to save new appointment
  // Future<void> _saveAppointmentToBackend(String name, int hour, String status) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('YOUR_BACKEND_URL/api/appointments'),
  //       headers: {
  //         'Authorization': 'Bearer YOUR_API_KEY',
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode({
  //         'name': name,
  //         'time': hour,
  //         'date': selectedDay.toIso8601String(),
  //         'status': status,
  //       }),
  //     );
  //
  //     if (response.statusCode == 201) {
  //       final Color statusColor = status == 'Completed'
  //           ? const Color(0xFF22C55E)
  //           : status == 'Pending'
  //           ? const Color(0xFFF59E0B)
  //           : const Color(0xFFEF4444);
  //
  //       if (mounted) {
  //         setState(() {
  //           appointments[hour] = SlotData(name, statusColor);
  //         });
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Session added for $name at ${_formatHour12(hour)}')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error saving appointment: $e')),
  //       );
  //     }
  //   }
  // }

  // TODO: API INTEGRATION - Add this method to update appointment
  // Future<void> _updateAppointmentOnBackend(int hour, String name, String status) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('YOUR_BACKEND_URL/api/appointments/$hour'),
  //       headers: {
  //         'Authorization': 'Bearer YOUR_API_KEY',
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode({
  //         'name': name,
  //         'status': status,
  //         'date': selectedDay.toIso8601String(),
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Color statusColor = status == 'Completed'
  //           ? const Color(0xFF22C55E)
  //           : status == 'Pending'
  //           ? const Color(0xFFF59E0B)
  //           : const Color(0xFFEF4444);
  //
  //       if (mounted) {
  //         setState(() {
  //           appointments[hour] = SlotData(name, statusColor);
  //         });
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Appointment updated')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error updating appointment: $e')),
  //       );
  //     }
  //   }
  // }

  // TODO: API INTEGRATION - Add this method to delete appointment
  // Future<void> _deleteAppointmentFromBackend(int hour) async {
  //   try {
  //     final response = await http.delete(
  //       Uri.parse('YOUR_BACKEND_URL/api/appointments/$hour?date=${selectedDay.toIso8601String()}'),
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
              onTap: () => _inlineShowAddSessionDialog(context),
            ),
            const SizedBox(width: 16.0),
            RoundAction(
              icon: Icons.notifications_none,
              label: 'Set\nReminder',
              onTap: () => _inlineShowSetReminderDialog(context),
            ),
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
                  value: selectedStatus,
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
                // TODO: API INTEGRATION - Call backend delete method
                // _deleteAppointmentFromBackend(hour);

                // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
                if (mounted) {
                  setState(() {
                    appointments.remove(hour);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment deleted')),
                  );
                }
                // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameCtrl.text;
                  Navigator.of(ctx).pop();
                  // TODO: API INTEGRATION - Call backend update method
                  // _updateAppointmentOnBackend(hour, name, selectedStatus);

                  // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
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
                  // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _inlineShowAddSessionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    int? selectedHour;
    String selectedStatus = 'Pending';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Session'),
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
                DropdownButtonFormField<int>(
                  value: selectedHour,
                  decoration: const InputDecoration(labelText: 'Time'),
                  hint: const Text('Select time'),
                  items: List.generate(24, (i) {
                    final timeStr = _formatHour12(i);
                    return DropdownMenuItem(value: i, child: Text(timeStr));
                  }),
                  onChanged: (val) {
                    setDialogState(() => selectedHour = val);
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
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
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameCtrl.text;
                  final hour = selectedHour!;

                  Navigator.of(ctx).pop();

                  // TODO: API INTEGRATION - Call backend save method
                  // _saveAppointmentToBackend(name, hour, selectedStatus);

                  // REMOVE THIS BLOCK AFTER API INTEGRATION ↓↓↓
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
                      SnackBar(
                        content: Text(
                          'Session added for $name at ${_formatHour12(hour)}',
                        ),
                      ),
                    );
                  }
                  // REMOVE THIS BLOCK AFTER API INTEGRATION ↑↑↑
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
  // TODO: API INTEGRATION - Fetch appointments for new date
  // _fetchAppointmentsFromBackend();

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

  String _formatHour12(int hour24) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour = hour24 % 12;
    if (hour == 0) hour = 12;
    final label = hour.toString().padLeft(2, '0');
    return '$label:00 $period';
  }
}

void _inlineShowSetReminderDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final noteCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Set Reminder'),
      content: Form(
        key: formKey,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 220.0,
            child: TextFormField(
              controller: noteCtrl,
              minLines: 1,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Reminder note',
                hintText: 'Short note',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              style: const TextStyle(fontSize: 14.0),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
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
              // TODO: API INTEGRATION - Save reminder to backend
              // _saveReminderToBackend(noteCtrl.text);

              // REMOVE THIS LINE AFTER API INTEGRATION ↓
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Reminder set')));
              // REMOVE THIS LINE AFTER API INTEGRATION ↑
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}