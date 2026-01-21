import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../config/api_config.dart';

// File-level status color helper used by sidebar and other widgets
Color statusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('completed')) return const Color(0xFF4CAF50);
  if (s.contains('pending')) return const Color(0xFFFFC107);
  return Colors.grey;
}

// Reusable sidebar widget that fetches appointments for a given date
class SidebarAppointmentList extends StatelessWidget {
  final DateTime date;
  const SidebarAppointmentList({super.key, required this.date});

  Future<List<Appointment>> _fetchForDate() async {
    final all = await AppointmentService.getAllAppointments();
    final filtered = all.where((a) {
      try {
        final parsed = DateTime.tryParse(a.date) ?? DateFormat('yyyy-MM-dd').parseLoose(a.date);
        return parsed.year == date.year && parsed.month == date.month && parsed.day == date.day;
      } catch (_) {
        return false;
      }
    }).toList();
    // sort by time HH:mm
    filtered.sort((a, b) {
      try {
        final ap = a.time.split(':');
        final bp = b.time.split(':');
        final am = int.parse(ap[0]) * 60 + int.parse(ap[1]);
        final bm = int.parse(bp[0]) * 60 + int.parse(bp[1]);
        return am.compareTo(bm);
      } catch (_) {
        return a.time.compareTo(b.time);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Appointment>>(
      future: _fetchForDate(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Error loading appointments', style: theme.textTheme.bodySmall),
          );
        }
        final todays = snap.data ?? [];
        if (todays.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No appointments', style: theme.textTheme.bodySmall),
          );
        }
        return Column(
          children: todays.map((a) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: statusColor(a.status), child: const Icon(Icons.person, size: 16, color: Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.sessionType.isNotEmpty ? a.sessionType : 'Session', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  Text(a.time),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AppointmentSection extends StatefulWidget {
  const AppointmentSection({super.key});

  @override
  State<AppointmentSection> createState() => _AppointmentSectionState();
}

class _AppointmentSectionState extends State<AppointmentSection> {
  bool _loading = true;
  String? _error;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppointmentService.getAllAppointments();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<DateTime> _weekDays(DateTime center) {
    final int weekday = center.weekday; // 1=Mon .. 7=Sun
    final start = center.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  // Note: appointment filtering and status color are handled by
  // SidebarAppointmentList and the top-level `statusColor` helper.

  Future<void> _showAddAppointmentDialog() async {
    final formKey = GlobalKey<FormState>();
    String childName = '';
    String sessionType = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        TimeOfDay? localPickedTime;
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          final messenger = ScaffoldMessenger.of(ctx2);

          return AlertDialog(
            title: const Text('Add Appointment'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Child name'),
                    onChanged: (v) => childName = v.trim(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter child name' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Test'),
                    items: const [
                      DropdownMenuItem(value: 'Handwriting Assessment', child: Text('Handwriting Assessment')),
                      DropdownMenuItem(value: 'Pressure Test', child: Text('Pressure Test')),
                      DropdownMenuItem(value: 'Speed Test', child: Text('Speed Test')),
                    ],
                    onChanged: (v) => sessionType = v ?? '',
                    validator: (v) => (v == null || v.isEmpty) ? 'Select test' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(localPickedTime == null
                            ? 'Select time'
                            : '${localPickedTime!.hour.toString().padLeft(2, '0')}:${localPickedTime!.minute.toString().padLeft(2, '0')}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx2, initialTime: TimeOfDay(hour: 9, minute: 0));
                          if (t != null) {
                            setStateDialog(() {
                              localPickedTime = t;
                            });
                          }
                        },
                        child: const Text('Pick Time'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  if (localPickedTime == null) {
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Please pick a time')));
                    return;
                  }

                  // Build date/time strings
                  final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final picked = localPickedTime!;
                  final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

                    try {
                      final therapistName = (await Config.getUserName()) ?? 'Therapist';
                      await AppointmentService.addAppointment(
                        childName: childName,
                        therapistName: therapistName,
                        sessionType: sessionType,
                        date: dateStr,
                        time: timeStr,
                      );
                      // close dialog first
                      Navigator.pop(ctx2);
                      // refresh and show snackbar in a post-frame callback to avoid using
                      // build context across async gaps.
                      if (!mounted) return;
                      _loadAppointments();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        messenger.showSnackBar(const SnackBar(content: Text('Appointment added')));
                      });
                    } catch (e) {
                      Navigator.pop(ctx2);
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                      });
                    }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading appointments', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadAppointments, child: const Text('Retry')),
          ],
        ),
      );
    }

    final days = _weekDays(_selectedDate);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: month + arrows + small note
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                          });
                        },
                      ),
                      Text(monthLabel, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Work in Progress', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            // Big buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Appointment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    backgroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Set Reminder'),
                      content: const Text('Set Reminder UI will be implemented here.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
                    ),
                  ),
                  icon: const Icon(Icons.notifications, size: 20),
                  label: const Text('Set Reminder'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Week day bubbles
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final d = days[idx];
              final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = d),
                child: Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat.E().format(d), style: TextStyle(color: isSelected ? Colors.white : Colors.black54)),
                      const SizedBox(height: 6),
                      Text(DateFormat.d().format(d), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // Time slots (left column main area)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: time slots (12 AM to 12 PM)
                  Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: 24, // hours 0..23 (full day)
                  itemBuilder: (context, idx) {
                    final hour = idx; // 0..23
                    final timeLabel = DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour));

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 80, child: Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: const Text(''),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 24),

              // Right: selected-day appointment summary + legend
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small card showing selected date and appointments
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SidebarAppointmentList(date: _selectedDate),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('Color coding:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF4CAF50), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Completed'),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFFFC107), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Pending'),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
