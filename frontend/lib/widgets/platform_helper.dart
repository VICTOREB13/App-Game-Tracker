import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlatformHelper {
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
    } else if (p.contains('nintendo') ||
        p.contains('switch') ||
        p.contains('wii') ||
        p.contains('ds') ||
        p.contains('64')) {
      return isColor
          ? 'assets/images/nintendo_PNG19.png'
          : 'assets/images/nintendo-logo-1-1.png';
    } else if (p.contains('xbox')) {
      return isColor
          ? 'assets/images/logo-Xbox.png'
          : 'assets/images/xbox-2-logo-png-transparent.png';
    } else if (p.contains('steam')) {
      return isColor
          ? 'assets/images/steam-logo.png'
          : 'assets/images/steam-logo-steam-icon-transparent-free-png.webp';
    } else if (p.contains('gog')) {
      return 'assets/images/GOG_LOGO_DARK.png';
    } else if (p.contains('epic')) {
      return 'assets/images/Epic_Games_logo.svg.webp';
    } else if (p == 'pc' || p == 'computadora') {
      return 'assets/images/steam-logo.png';
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
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
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
          getIcon(platform, size: iconSize, color: color, isColor: isColor),
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
