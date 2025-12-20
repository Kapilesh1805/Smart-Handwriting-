import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeService() {
    _loadTheme();
  }
  
  // Load theme from local storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  // Toggle theme and save to local storage
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    // ==================== IMPORTANT: Notify all listeners ====================
    notifyListeners();
    // ========================================================================
    
    // TODO: ADD BACKEND API - Save theme preference
    // _saveThemeToBackend();
  }

  // ==================== LIGHT THEME ====================
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    primaryColor: const Color(0xFFFF6B35),
    scaffoldBackgroundColor: const Color(0xFFFFF8EE),
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFF6FBAFF),
      surface: Color(0xFFFFF8EE),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF6B35),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(color: Color(0xFF6B7280)),
      labelLarge: TextStyle(color: Color(0xFF1F2937)),
    ),
  );
  // =====================================================

  // ==================== DARK THEME ====================
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: const Color(0xFFFF6B35),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFF6FBAFF),
      surface: Color(0xFF2D2D2D),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D2D2D),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFAFAFA)),
      bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
      labelLarge: TextStyle(color: Color(0xFFFAFAFA)),
    ),
  );
  // =====================================================

  // TODO: ADD BACKEND API - Save theme preference
  // Future<void> _saveThemeToBackend() async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('YOUR_API_URL/api/user/preferences'),
  //       headers: {
  //         'Authorization': 'Bearer YOUR_TOKEN',
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode({
  //         'theme': _isDarkMode ? 'dark' : 'light',
  //       }),
  //     );
  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to save theme: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error saving theme: $e');
  //   }
  // }

  // TODO: ADD BACKEND API - Load user's theme preference from backend
  // Future<void> _loadThemeFromBackend() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('YOUR_API_URL/api/user/preferences'),
  //       headers: {'Authorization': 'Bearer YOUR_TOKEN'},
  //     );
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       _isDarkMode = data['theme'] == 'dark';
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     print('Error loading theme: $e');
  //   }
  // }
}