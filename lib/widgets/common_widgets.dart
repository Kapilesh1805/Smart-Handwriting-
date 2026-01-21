import 'package:flutter/material.dart';
import '../models/app_models.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  const CustomCard({super.key, required this.child});

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

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const FeatureCard({super.key, required this.title, required this.icon, this.onTap});

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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppointmentTile extends StatelessWidget {
  final AppointmentItem item;
  const AppointmentTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: item.highlighted
            ? const Color(0xFF2D3748)
            : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 6.0,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: item.avatarAsset != null
              ? AssetImage(item.avatarAsset!) as ImageProvider
              : null,
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

class ScheduleCard extends StatelessWidget {
  final String year;
  final String month;
  final String day;
  final String weekday;
  final bool dark;
  const ScheduleCard({
    super.key,
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            month,
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            width: 72.0,
            height: 72.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFF6F8FC),
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
          Text(
            weekday,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class FloeLogo extends StatelessWidget {
  final double size;
  const FloeLogo({super.key, required this.size});

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