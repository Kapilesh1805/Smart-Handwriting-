import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // ==================== USE THEME COLORS ====================
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
              ? Colors.grey.shade800 
              : Colors.grey.shade200,
          width: 1,
        ),
        // ==================================================
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFFF6B35)).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFFFF6B35),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            // ==================== USE THEME COLORS ====================
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            // ==================================================
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  // ==================== USE THEME COLORS ====================
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                  // ==================================================
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              // ==================== USE THEME COLORS ====================
              color: theme.textTheme.bodyMedium?.color,
              // ==================================================
            ),
      ),
    );
  }
}