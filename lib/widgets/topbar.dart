import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String? userName;
  
  const TopBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    // ==================== GET THEME ====================
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // ==================================================

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      // ==================== USE THEME COLOR ====================
      color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      // ==================================================
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
                // ==================== USE THEME COLOR ====================
                color: isDarkMode
                    ? Colors.grey.shade800
                    : const Color(0xFFEFF3F9),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : const Color(0xFFE3E8F0),
                ),
                // ==================================================
              ),
              child: Center(
                child: TextField(
                  // ==================== USE THEME COLOR ====================
                  cursorColor: isDarkMode
                      ? Colors.grey.shade300
                      : const Color(0xFF2D3748),
                  // ==================================================
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search Here',
                    // ==================== USE THEME COLOR ====================
                    hintStyle: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade500
                          : const Color(0xFF718096),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode
                          ? Colors.grey.shade500
                          : const Color(0xFF718096),
                    ),
                    // ==================================================
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  // ==================== USE THEME COLOR ====================
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  ),
                  // ==================================================
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          SquareIconButton(
            icon: Icons.tune,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 12.0),
          SquareIconButton(
            icon: Icons.notifications_outlined,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 16.0),
          Row(
            children: [
              CircleAvatar(
                radius: 18.0,
                // ==================== USE THEME COLOR ====================
                backgroundColor: isDarkMode
                    ? Colors.grey.shade800
                    : const Color(0xFFEFF3F9),
                child: Icon(
                  Icons.person,
                  color: isDarkMode
                      ? Colors.grey.shade300
                      : const Color(0xFF2D3748),
                ),
                // ==================================================
              ),
              const SizedBox(width: 8.0),
              Text(
                userName ?? 'User',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.grey.shade300
                      : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  // ==================== ADD isDarkMode PARAMETER ====================
  final bool isDarkMode;

  const SquareIconButton({
    super.key,
    required this.icon,
    required this.isDarkMode,
  });
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.0,
      height: 44.0,
      decoration: BoxDecoration(
        // ==================== USE THEME COLOR ====================
        color: isDarkMode
            ? Colors.grey.shade800
            : const Color(0xFFEFF3F9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey.shade700
              : const Color(0xFFE3E8F0),
        ),
        // ==================================================
      ),
      child: IconButton(
        // ==================== USE THEME COLOR ====================
        icon: Icon(
          icon,
          color: isDarkMode
              ? Colors.grey.shade300
              : const Color(0xFF2D3748),
        ),
        // ==================================================
        onPressed: () {},
      ),
    );
  }
}