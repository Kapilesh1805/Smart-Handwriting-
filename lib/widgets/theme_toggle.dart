import 'package:flutter/material.dart';

class ThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeToggle({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDarkMode),
      child: Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode 
              ? const Color(0xFF34495E) 
              : const Color(0xFFBDC3C7),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              size: 16,
              color: isDarkMode 
                  ? const Color(0xFF34495E) 
                  : const Color(0xFFFFA726),
            ),
          ),
        ),
      ),
    );
  }
}