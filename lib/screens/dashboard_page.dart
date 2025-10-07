import 'package:flutter/material.dart';
import 'placeholder_pages.dart';

class DashboardPage extends StatefulWidget {
  final List<AppointmentItem> appointments;
  final UserProfile? user;
  const DashboardPage({super.key, this.appointments = const [], this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedSection = 'Dashboard';

  void _onSelectSection(String label) {
    setState(() {
      _selectedSection = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Sidebar(selectedLabel: _selectedSection, onSelect: _onSelectSection),
            Expanded(
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _selectedSection == 'Appointment'
                                ? const _AppointmentMain()
                                : const _MainContent(),
                          ),
                          SizedBox(width: 24.0),
                          Expanded(
                            flex: 1,
                            child: _RightPanel(
                              appointments: widget.appointments,
                              user: widget.user,
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

class _Sidebar extends StatelessWidget {
  final String selectedLabel;
  final void Function(String) onSelect;
  // ignore: unused_element_parameter
  const _Sidebar({super.key, required this.selectedLabel, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<_IconLabel, String>> items = [
      MapEntry(const _IconLabel(Icons.dashboard_outlined), 'Dashboard'),
      MapEntry(const _IconLabel(Icons.event_outlined), 'Appointment'),
      MapEntry(const _IconLabel(Icons.draw_outlined), 'Writing Interface'),
      MapEntry(const _IconLabel(Icons.child_care_outlined), 'Childrens'),
      MapEntry(const _IconLabel(Icons.insert_chart_outlined), 'Report'),
      MapEntry(const _IconLabel(Icons.border_color_outlined), 'Pre writing'),
      MapEntry(const _IconLabel(Icons.settings_outlined), 'Settings'),
      MapEntry(const _IconLabel(Icons.person_outline), 'My Account'),
      MapEntry(const _IconLabel(Icons.logout), 'Sign Out'),
    ];

    return Container(
      width: 220.0,
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        children: [
          const SizedBox(height: 8.0),
          ...items.map((e) => _SidebarItem(
                iconLabel: e.key,
                label: e.value,
                selected: e.value == selectedLabel,
                onTap: () => onSelect(e.value),
              )),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _IconLabel iconLabel;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({required this.iconLabel, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8EDF5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(iconLabel.icon, color: const Color(0xFF2D3748)),
        title: Text(label, style: const TextStyle(color: Color(0xFF2D3748))),
        onTap: onTap ?? () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlaceholderScreen(title: label)),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            height: 72.0,
            child: Image.asset(
              'assets/images/floe_banner.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3F9),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE3E8F0)),
              ),
              child: const Center(
                child: TextField(
                  cursorColor: Color(0xFF2D3748),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search Here',
                    hintStyle: TextStyle(color: Color(0xFF718096)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF718096)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  style: TextStyle(color: Color(0xFF1F2937)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          _SquareIconButton(icon: Icons.tune),
          const SizedBox(width: 12.0),
          _SquareIconButton(icon: Icons.notifications_outlined),
          const SizedBox(width: 16.0),
          const CircleAvatar(radius: 18.0, backgroundColor: Color(0xFFEFF3F9), child: Icon(Icons.person, color: Color(0xFF2D3748))),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

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
                final double height = (cardHeight * 0.9).clamp(180.0, cardHeight);
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
            _FeatureCard(
              title: 'Add new\nchild profile',
              icon: Icons.child_care,
              onTap: () => _showAddChildDialog(context),
            ),
            const SizedBox(width: 16.0),
            _FeatureCard(
              title: 'Saved\nAssessments',
              icon: Icons.description_outlined,
              onTap: () => _showSavedAssessmentsDialog(context),
            ),
            const SizedBox(width: 16.0),
            _FeatureCard(
              title: 'Generate\nreports',
              icon: Icons.insert_chart_outlined,
              onTap: () => _showGenerateReportsDialog(context),
            ),
            const SizedBox(width: 16.0),
            _FeatureCard(
              title: 'Progress\nanalytics',
              icon: Icons.show_chart,
              onTap: () => _showProgressAnalyticsDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}

// Inline Appointment main view to keep sidebar persistent
class _AppointmentMain extends StatefulWidget {
  const _AppointmentMain();
  @override
  State<_AppointmentMain> createState() => _AppointmentMainState();
}

class _AppointmentMainState extends State<_AppointmentMain> {
  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final DateTime start = selectedDay.subtract(Duration(days: selectedDay.weekday));
    final dates = List<DateTime>.generate(6, (i) => start.add(Duration(days: i + 1)));
    return ListView(
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
            _RoundAction(icon: Icons.add, label: 'Add Session', onTap: () => _inlineShowAddSessionDialog(context)),
            const SizedBox(width: 16.0),
            _RoundAction(icon: Icons.notifications_none, label: 'Set\nReminder', onTap: () => _inlineShowSetReminderDialog(context)),
          ],
        ),
        const SizedBox(height: 12.0),
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
        const SizedBox(height: 6.0),
        const Text('Work in Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.0)),
        const SizedBox(height: 6.0),
        SizedBox(
          height: 340.0,
          child: _buildCompactTimeline(),
        ),
        const SizedBox(height: 8.0),
        const _Legend(color: Color(0xFF22C55E), label: 'Completed'),
        const _Legend(color: Color(0xFFF59E0B), label: 'Pending'),
        const _Legend(color: Color(0xFFEF4444), label: 'Missed'),
      ],
    );
  }

  Widget _buildCompactTimeline() {
    final Map<int, _SlotData> data = {
    };
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.0),
                ),
              ),
              const SizedBox(width: 12.0),
              if (slot != null) ...[
                Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 4.0),
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: slot.color, width: 2.0),
                      ),
                      child: const Icon(Icons.person, size: 14.0, color: Color(0xFF64748B)),
                    ),
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
                          const Icon(Icons.edit, size: 16.0, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ),
              ]  ],
          ),
        );
      },
    );
  } 
  void _shiftDays(int delta) => setState(() => selectedDay = selectedDay.add(Duration(days: delta)));

  String _formatMonthYear(DateTime d) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatHour12(int hour24) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour = hour24 % 12;
    if (hour == 0) hour = 12;
    final label = hour.toString().padLeft(2, '0');
    return '$label:00 $period';
  }
}

void _inlineShowAddSessionDialog(BuildContext context) {
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              style: const TextStyle(fontSize: 14.0),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${nameCtrl.text}')),
                );
              }
            },
            child: const Text('Save'),
          )
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
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Saved Assessments'),
      content: const Text('This will list saved assessments from backend.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    ),
  );
}

void _showGenerateReportsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Generate reports'),
      content: const Text('Choose parameters and generate downloadable reports.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    ),
  );
}

void _showProgressAnalyticsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Progress analytics'),
      content: const Text('Analytics and charts will appear here.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    ),
  );
}

class _RightPanel extends StatelessWidget {
  final List<AppointmentItem> appointments;
  final UserProfile? user;
  const _RightPanel({required this.appointments, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Card(
          child: Row(
            children: [
              const CircleAvatar(radius: 20.0, child: Icon(Icons.person)),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  user != null
                      ? '${user!.name}\n${user!.occupation}'
                      : '—\n—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12.0),
              Row(
                children: const [
                  Expanded(
                    child: _ScheduleCard(
                      year: '2025',
                      month: 'September',
                      day: '20',
                      weekday: 'Monday',
                      dark: true,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: _ScheduleCard(
                      year: '2025',
                      month: 'September',
                      day: '22',
                      weekday: 'Tuesday',
                      dark: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12.0),
              if (appointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFE3E8F0)),
                  ),
                  child: const Text('No appointments'),
                )
              else
                ...appointments.map((a) => _AppointmentTile(item: a)).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Dr. Alfredo Torres'),
                subtitle: Text('You automatically lose the chances you don\'t take.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const _FeatureCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Ink(
            height: 140.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36.0, color: const Color(0xFF334155)),
                const SizedBox(height: 12.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: child,
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentItem item;
  const _AppointmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: item.highlighted ? const Color(0xFF2D3748) : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: item.avatarAsset != null ? AssetImage(item.avatarAsset!) as ImageProvider : null,
          child: item.avatarAsset == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: item.highlighted ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          'Child Name : ${item.childName}  ·  ${item.timeLabel}',
          style: TextStyle(
            color: item.highlighted ? Colors.white70 : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

// _ScheduleChip removed (replaced by _ScheduleCard)

class _ScheduleCard extends StatelessWidget {
  final String year;
  final String month;
  final String day;
  final String weekday;
  final bool dark;
  const _ScheduleCard({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = dark ? const Color(0xFF2D3748) : Colors.white;
    final Color fg = dark ? Colors.white : const Color(0xFF111827);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(year, style: TextStyle(color: fg.withOpacity(0.7), fontSize: 12.0, fontWeight: FontWeight.w600)),
          Text(month, style: TextStyle(color: fg.withOpacity(0.7), fontSize: 12.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8.0),
          Container(
            width: 72.0,
            height: 72.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? Colors.white.withOpacity(0.1) : const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: Text(
              day,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: 28.0,
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(weekday, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class AppointmentItem {
  final String title;
  final String childName;
  final String timeLabel;
  final String? avatarAsset;
  final bool highlighted;
  const AppointmentItem({
    required this.title,
    required this.childName,
    required this.timeLabel,
    this.avatarAsset,
    this.highlighted = false,
  });
}

class UserProfile {
  final String name;
  final String occupation;
  const UserProfile({required this.name, required this.occupation});
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  const _SquareIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.0,
      height: 44.0,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF2D3748)),
        onPressed: () {},
      ),
    );
  }
}

class _IconLabel {
  final IconData icon;
  const _IconLabel(this.icon);
}

class FloeLogo extends StatelessWidget {
  final double size;
  const FloeLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 8,
          height: size + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            'F',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.7,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          'FLOE',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// Helpers reused by inline Appointment view
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFE3E8F0)),
        ),
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
            decoration: BoxDecoration(
              color: const Color(0xFF2D3748),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date; final bool isSelected; final VoidCallback onTap;
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
            Text(
              dayNum,
              style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 6.0),
            Text(weekday, style: TextStyle(color: isSelected ? Colors.white70 : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}
// ignore: unused_element
class _Slot extends StatelessWidget {
  final String time; final String label; final Color color;
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
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 10.0, height: 10.0, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8.0),
          Text(label),
        ],
      ),
    );
  }
}

class _SlotData {
  final String label; final Color color;
  const _SlotData(this.label, this.color);
}


