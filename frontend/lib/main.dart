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
      title: 'Game Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),       // Neon cyan
          secondary: Color(0xFFFF2D78),     // Neon magenta
          tertiary: Color(0xFFFFBE0B),      // Neon amber
          surface: Color(0xFF141927),
          onSurface: Color(0xFFF0F2F5),
        ),
        cardColor: const Color(0xFF141927),
        dividerColor: const Color(0xFF1C2237),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          // Display headings use Space Grotesk
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF0F2F5),
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF0F2F5),
          ),
          headlineSmall: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F2F5),
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F2F5),
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFFF0F2F5),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFF0F2F5),
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7394),
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: const Color(0xFF6B7394),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF0F2F5),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF0F2F5)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141927),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1C2237)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1C2237)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7394)),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF3A4060)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            foregroundColor: const Color(0xFF0A0E1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1C2237),
          selectedColor: const Color(0xFF00F0FF),
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
