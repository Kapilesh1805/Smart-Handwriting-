import 'package:flutter/material.dart';
import '../screens/landing_page.dart';
import 'placeholder_pages.dart';

class Sidebar extends StatelessWidget {
  final String selectedLabel;
  final void Function(String) onSelect;

  const Sidebar({
    super.key,
    required this.selectedLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // ==================== GET THEME ====================
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // ==================================================

    final List<MapEntry<IconData, String>> items = [
      const MapEntry(Icons.dashboard_outlined, 'Dashboard'),
      const MapEntry(Icons.event_outlined, 'Appointment'),
      const MapEntry(Icons.draw_outlined, 'Writing Interface'),
      const MapEntry(Icons.child_care_outlined, 'Childrens'),
      const MapEntry(Icons.insert_chart_outlined, 'Report'),
      const MapEntry(Icons.border_color_outlined, 'Pre writing'),
      const MapEntry(Icons.description_outlined, 'Sentence Writing'),
      const MapEntry(Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      width: 220.0,
      // ==================== USE THEME COLOR ====================
      color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      // ==================================================
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        children: [
          const SizedBox(height: 8.0),
          ...items.map(
            (e) => SidebarItem(
              icon: e.key,
              label: e.value,
              selected: e.value == selectedLabel,
              onTap: () => onSelect(e.value),
              isDarkMode: isDarkMode,
            ),
          ),
          // ==================== SIGN OUT BUTTON ====================
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SignOutButton(isDarkMode: isDarkMode),
          ),
          // =====================================================
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  // ==================== ADD isDarkMode PARAMETER ====================
  final bool isDarkMode;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    required this.isDarkMode,
  });
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        // ==================== USE THEME COLOR ====================
        color: selected
            ? (isDarkMode
                ? const Color(0xFF3D3D3D)
                : const Color(0xFFE8EDF5))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        // ==================================================
      ),
      child: ListTile(
        // ==================== USE THEME COLOR ====================
        leading: Icon(
          icon,
          color: isDarkMode
              ? (selected ? const Color(0xFFFF6B35) : Colors.grey.shade300)
              : const Color(0xFF2D3748),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isDarkMode
                ? (selected ? const Color(0xFFFF6B35) : Colors.grey.shade300)
                : const Color(0xFF2D3748),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        // ==================================================
        onTap:
            onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceholderScreen(title: label),
                ),
              );
            },
      ),
    );
  }
}

// ==================== SIGN OUT BUTTON WIDGET ====================
class SignOutButton extends StatelessWidget {
  final bool isDarkMode;

  const SignOutButton({super.key, required this.isDarkMode});

  // ==================== SIGN OUT FUNCTION ====================
  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // ==================== REDIRECT TO LOGIN PAGE ====================
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
              // ================================================================
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleSignOut(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          // ==================== USE THEME COLOR ====================
          color: isDarkMode
              ? Colors.red.shade900.withOpacity(0.2)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDarkMode
                ? Colors.red.shade800.withOpacity(0.5)
                : Colors.red.shade200,
          ),
          // ==================================================
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red.shade600,
              size: 20,
            ),
            const SizedBox(width: 12.0),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==============================================================