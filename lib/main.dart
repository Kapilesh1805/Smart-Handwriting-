import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme_service.dart';
import 'screens/landing_page.dart';
import 'services/handwriting_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run backend health check on app start
  print('🔌 Running backend health check...');
  final backendHealthy = await HandwritingService.checkBackendStatus();
  print(backendHealthy ? '✅ Backend is online' : '⚠️ Backend is offline');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const HandwritingApp(),
    ),
  );
}

class HandwritingApp extends StatelessWidget {
  const HandwritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: 'Handwriting AI',
      debugShowCheckedModeBanner: false,
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const LandingPage(),
    );
  }
}