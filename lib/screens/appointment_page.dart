import 'package:flutter/material.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final DateTime start = selectedDay.subtract(Duration(days: selectedDay.weekday));
    final dates = List<DateTime>.generate(7, (i) => start.add(Duration(days: i + 1)));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointment'),
      ),
      body: Row(
        children: [
          // Main content
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Text(
                        _formatMonthYear(selectedDay),
                        style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 16.0),
                      _IconPill(icon: Icons.chevron_left, onTap: () => _shiftDays(-7)),
                      const SizedBox(width: 8.0),
                      _IconPill(icon: Icons.chevron_right, onTap: () => _shiftDays(7)),
                      const Spacer(),
                      _RoundAction(
                        icon: Icons.add,
                        label: 'Add Session',
                        onTap: () => _showAddSessionDialog(context),
                      ),
                      const SizedBox(width: 16.0),
                      _RoundAction(
                        icon: Icons.notifications_none,
                        label: 'Set\nReminder',
                        onTap: () => _showSetReminderDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // calendar strip
                  Row(
                    children: dates
                        .map((d) => Expanded(
                              child: _DateChip(
                                date: d,
                                isSelected: _isSameDay(d, selectedDay),
                                onTap: () => setState(() => selectedDay = d),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Work in Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12.0),
                  // time slots
                  ..._buildTimeSlots(),
                ],
              ),
            ),
          ),
          // Right panel (simplified)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(right: 24.0, top: 24.0, bottom: 24.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE3E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Color coding:', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 10.0),
                  _Legend(color: Color(0xFF22C55E), label: 'Completed'),
                  _Legend(color: Color(0xFFF59E0B), label: 'Pending'),
                  _Legend(color: Color(0xFFEF4444), label: 'Missed'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildTimeSlots() {
    final slots = [
      _Slot(time: '8:00 AM', label: 'child name', color: const Color(0xFFEF4444)),
      _Slot(time: '10:00 AM', label: 'child name', color: const Color(0xFF22C55E)),
      _Slot(time: '12:00 AM', label: 'child name', color: const Color(0xFFF59E0B)),
      _Slot(time: '14:00 PM', label: 'child name', color: const Color(0xFFF59E0B)),
      _Slot(time: '16:00 PM', label: 'child name', color: const Color(0xFFF59E0B)),
    ];
    return slots
        .map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: s,
            ))
        .toList();
  }

  void _shiftDays(int delta) {
    setState(() => selectedDay = selectedDay.add(Duration(days: delta)));
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _showAddSessionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Session'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Child name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'Time (e.g., 4:00 PM)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session added')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showSetReminderDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Reminder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Reminder note'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;
  const _DateChip({required this.date, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dayNum = date.day.toString().padLeft(2, '0');
    final weekday = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday - 1];
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3748) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFE3E8F0)),
        ),
        child: Column(
          children: [
            Text('$dayNum', style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF1F2937))),
            const SizedBox(height: 6.0),
            Text(weekday, style: TextStyle(color: isSelected ? Colors.white70 : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String time;
  final String label;
  final Color color;
  const _Slot({required this.time, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 80.0, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8.0),
        const CircleAvatar(radius: 14.0, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.image, size: 16.0, color: Color(0xFF334155))),
        const SizedBox(width: 8.0),
        Expanded(
          child: Container(
            height: 22.0,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        )
      ],
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _IconPill({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Ink(
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: const Color(0xFFE3E8F0))),
        child: Icon(icon, color: const Color(0xFF2D3748)),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Ink(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(color: const Color(0xFF2D3748), borderRadius: BorderRadius.circular(20.0)),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label; const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        Container(width: 10.0, height: 10.0, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8.0),
        Text(label),
      ]),
    );
  }
}


