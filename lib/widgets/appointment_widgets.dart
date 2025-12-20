import 'package:flutter/material.dart';

class IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const IconPill({super.key, required this.icon, required this.onTap});
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

class RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
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
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;
  const DateChip({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final dayNum = date.day.toString().padLeft(2, '0');
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][date.weekday - 1];
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              weekday,
              style: TextStyle(
                color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String label;
  const Legend({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8.0),
          Text(label),
        ],
      ),
    );
  }
}

class SlotData {
  final String label;
  final Color color;
  const SlotData(this.label, this.color);
}