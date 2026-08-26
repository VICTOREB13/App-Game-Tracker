import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notion_service.dart';
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

  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isConfigured = NotionService.instance.isConfigured;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Victor Engineer - Game Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDC2626), // Victor Engineer Signature Red
          secondary: Color(0xFFEF4444),
          tertiary: Color(0xFFF59E0B),
          surface: Color(0xFF121215),
          onSurface: Color(0xFFFAFAFA),
        ),
        cardColor: const Color(0xFF121215),
        dividerColor: const Color(0xFF27272A),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFAFAFA),
          ),
          headlineMedium: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFAFAFA),
          ),
          headlineSmall: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
          ),
          titleLarge: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFFFAFAFA),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFFAFAFA),
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFFA1A1AA),
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: const Color(0xFF71717A),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF09090B),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFAFAFA),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFFAFAFA)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121215),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF27272A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF27272A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFFA1A1AA)),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: const Color(0xFFFAFAFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF18181B),
          selectedColor: const Color(0xFFDC2626),
          labelStyle: GoogleFonts.inter(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        useMaterial3: true,
      ),
      home: isConfigured ? const DashboardScreen() : const SetupScreen(),
    );
  }
}
