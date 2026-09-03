import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._();
  ThemeManager._();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static const String _prefKey = 'preferred_theme_mode';

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey) ?? 'dark';
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.dark;
          break;
      }
      notifyListeners();
    } catch (_) { /* ignore */ }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.system) val = 'system';
      await prefs.setString(_prefKey, val);
    } catch (_) { /* ignore */ }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

class AppColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Background
  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF09090B) : const Color(0xFFFAFAFA);

  // Surface / Cards
  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF121215) : const Color(0xFFFFFFFF);

  // Secondary surface (hover, inputs, chips)
  static Color surfaceSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);

  // Borders / Dividers
  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

  // Text Primary
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);

  // Text Secondary
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  // Text Muted
  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

  // Victor Engineer Signature Red (consistent brand accent across themes)
  static const Color primary = Color(0xFFDC2626);
  static const Color primaryLight = Color(0xFFEF4444);
}

class AppTheme {
  // --- DARK THEME (Obsidian Zinc - Preserved 100%) ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09090B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFDC2626),
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
    );
  }

  // --- LIGHT THEME (Crisp Zinc Light - Clean & Anti-Slop) ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFDC2626),
        secondary: Color(0xFFEF4444),
        tertiary: Color(0xFFF59E0B),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF09090B),
      ),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE4E4E7),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF09090B),
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF09090B),
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF09090B),
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF09090B),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF09090B),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF09090B),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF71717A),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: const Color(0xFFA1A1AA),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF09090B),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF09090B)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFFA1A1AA)),
      ),
    );
  }
}
