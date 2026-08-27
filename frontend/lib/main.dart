import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notion_service.dart';
import 'services/theme_manager.dart';
import 'screens/dashboard.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved Notion credentials
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('notion_token') ?? '';
  final gamesDbId = prefs.getString('notion_games_db_id') ?? '';

  if (token.isNotEmpty && gamesDbId.isNotEmpty) {
    NotionService.instance.configure(token: token, gamesDbId: gamesDbId);
  }

  // Load theme preference
  await ThemeManager.instance.loadTheme();

  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isConfigured = NotionService.instance.isConfigured;

    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Victor Engineer - Game Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeManager.instance.themeMode,
          home: isConfigured ? const DashboardScreen() : const SetupScreen(),
        );
      },
    );
  }
}
