import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlatformHelper {
  /// Catálogo estándar de plataformas soportadas por la aplicación
  static const List<String> allPlatforms = [
    'PC',
    'Mac',
    'Mobile',
    'Playstation 5',
    'Playstation 4',
    'Playstation 3',
    'Playstation 2',
    'Playstation 1',
    'Xbox',
    'Nintendo Switch',
    'Wii U',
    'Nintendo 64',
    'Nintendo DS',
    'GOG',
    'Epic Games',
  ];

  /// Normaliza nombres crudos de plataformas a su denominación canónica
  static String canonicalize(String rawPlatform) {
    final lower = rawPlatform.toLowerCase().trim();
    if (lower == 'pc' || lower.contains('steam') || lower.contains('windows')) {
      return 'PC';
    }
    if (lower.contains('playstation 5') || lower == 'ps5') return 'Playstation 5';
    if (lower.contains('playstation 4') || lower == 'ps4') return 'Playstation 4';
    if (lower.contains('playstation 3') || lower == 'ps3') return 'Playstation 3';
    if (lower.contains('playstation 2') || lower == 'ps2') return 'Playstation 2';
    if (lower.contains('playstation') || lower == 'ps1' || lower == 'psx') {
      return 'Playstation 1';
    }
    if (lower.contains('xbox series') ||
        lower.contains('xbox one') ||
        lower.contains('xbox 360') ||
        lower.contains('xbox')) {
      return 'Xbox';
    }
    if (lower.contains('switch')) return 'Nintendo Switch';
    if (lower.contains('wii u') || lower.contains('wii')) return 'Wii U';
    if (lower.contains('nintendo ds') ||
        lower.contains('3ds') ||
        lower.contains('ds')) {
      return 'Nintendo DS';
    }
    if (lower.contains('nintendo 64') || lower.contains('n64')) {
      return 'Nintendo 64';
    }
    if (lower.contains('mac') ||
        lower.contains('apple') ||
        lower.contains('macos')) {
      return 'Mac';
    }
    if (lower.contains('ios') ||
        lower.contains('android') ||
        lower.contains('mobile')) {
      return 'Mobile';
    }
    if (lower.contains('gog')) return 'GOG';
    if (lower.contains('epic')) return 'Epic Games';
    return rawPlatform;
  }

  /// Devuelve una lista ordenada de plataformas priorizando las recomendadas y la plataforma actual
  /// (normalizadas mediante [canonicalize] y sin duplicados), seguidas del catálogo estándar [allPlatforms].
  static List<String> getOrderedPlatforms({
    List<String>? recommended,
    String? currentPlatform,
  }) {
    final ordered = <String>[];
    final seen = <String>{};

    void addPlatform(String? raw) {
      if (raw == null) return;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      final canonical = canonicalize(trimmed);
      if (canonical.isNotEmpty && seen.add(canonical.toLowerCase())) {
        ordered.add(canonical);
      }
    }

    if (currentPlatform != null && currentPlatform.trim().isNotEmpty) {
      addPlatform(currentPlatform);
    }

    if (recommended != null) {
      for (final p in recommended) {
        addPlatform(p);
      }
    }

    for (final p in allPlatforms) {
      addPlatform(p);
    }

    return ordered;
  }

  static Color getColor(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('playstation') || p.contains('ps')) {
      return const Color(0xFF0070D1);
    } else if (p.contains('nintendo') ||
        p.contains('switch') ||
        p.contains('wii') ||
        p.contains('ds') ||
        p.contains('64')) {
      return const Color(0xFFE60012);
    } else if (p.contains('xbox')) {
      return const Color(0xFF107C10);
    } else if (p.contains('pc') ||
        p.contains('steam') ||
        p.contains('gog') ||
        p.contains('epic') ||
        p.contains('mac')) {
      return const Color(0xFF00F0FF);
    } else if (p.contains('mobile') ||
        p.contains('android') ||
        p.contains('ios')) {
      return const Color(0xFFFF2D78);
    } else {
      return const Color(0xFFFFBE0B);
    }
  }

  static String? getAssetPath(String platform, {bool isColor = true}) {
    final p = platform.toLowerCase();
    if (p.contains('playstation') || p.contains('ps')) {
      return isColor
          ? 'assets/images/Playstation_logo_colour.svg.webp'
          : 'assets/images/PlayStation-Logo.wine.png';
    } else if (p.contains('switch')) {
      return 'assets/images/nintendo_switch_logo.png';
    } else if (p.contains('nintendo') ||
        p.contains('wii') ||
        p.contains('ds') ||
        p.contains('64')) {
      return 'assets/images/nintendo_badge_red.png';
    } else if (p.contains('xbox')) {
      return isColor
          ? 'assets/images/xbox_logo_green.png'
          : 'assets/images/xbox-2-logo-png-transparent.png';
    } else if (p.contains('steam')) {
      return 'assets/images/steam-logo-steam-icon-transparent-free-png.webp';
    } else if (p.contains('gog')) {
      return 'assets/images/gog_logo_purple.png';
    } else if (p.contains('epic')) {
      return 'assets/images/epic_games_logo_bordered.png';
    } else if (p == 'pc' || p == 'computadora') {
      return 'assets/images/steam-logo-steam-icon-transparent-free-png.webp';
    }
    return null;
  }

  static Widget getIcon(
    String platform, {
    double size = 14,
    Color? color,
    bool useAsset = true,
    bool isColor = true,
  }) {
    final p = platform.toLowerCase();
    final iconColor = color ?? getColor(platform);
    final asset = useAsset ? getAssetPath(platform, isColor: isColor) : null;

    if (asset != null) {
      final bool shouldTint = color != null && !isColor;
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: shouldTint ? color : null,
        colorBlendMode: shouldTint ? BlendMode.srcIn : null,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackIcon(p, size, iconColor);
        },
      );
    }

    return _fallbackIcon(p, size, iconColor);
  }

  static Widget _fallbackIcon(String p, double size, Color iconColor) {
    if (p.contains('pc') ||
        p.contains('mac') ||
        p.contains('steam') ||
        p.contains('gog') ||
        p.contains('epic')) {
      return Icon(Icons.computer_rounded, size: size, color: iconColor);
    } else if (p.contains('mobile') ||
        p.contains('android') ||
        p.contains('ios')) {
      return Icon(Icons.smartphone_rounded, size: size, color: iconColor);
    } else {
      return Icon(Icons.gamepad_rounded, size: size, color: iconColor);
    }
  }

  static Widget buildBadge(
    String platform, {
    double fontSize = 9,
    double iconSize = 12,
    bool isColor = true,
  }) {
    final color = getColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getIcon(platform, size: iconSize, isColor: isColor),
          const SizedBox(width: 5),
          Text(
            platform,
            style: GoogleFonts.inter(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
