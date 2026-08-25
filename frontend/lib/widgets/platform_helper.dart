import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlatformHelper {
  static Color getColor(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('playstation') || p.contains('ps')) {
      return const Color(0xFF0070D1);
    } else if (p.contains('nintendo') || p.contains('switch') || p.contains('wii') || p.contains('ds') || p.contains('64')) {
      return const Color(0xFFE60012);
    } else if (p.contains('xbox')) {
      return const Color(0xFF107C10);
    } else if (p.contains('pc') || p.contains('steam') || p.contains('epic') || p.contains('gog') || p.contains('mac')) {
      return const Color(0xFF00F0FF);
    } else if (p.contains('mobile') || p.contains('android') || p.contains('ios')) {
      return const Color(0xFFFF2D78);
    } else {
      return const Color(0xFFFFBE0B);
    }
  }

  static Widget getIcon(String platform, {double size = 14, Color? color}) {
    final p = platform.toLowerCase();
    final iconColor = color ?? getColor(platform);

    if (p.contains('pc') || p.contains('mac') || p.contains('steam') || p.contains('gog') || p.contains('epic')) {
      return Icon(Icons.computer_rounded, size: size, color: iconColor);
    } else if (p.contains('mobile') || p.contains('android') || p.contains('ios')) {
      return Icon(Icons.smartphone_rounded, size: size, color: iconColor);
    } else {
      return Icon(Icons.gamepad_rounded, size: size, color: iconColor);
    }
  }

  static Widget buildBadge(String platform, {double fontSize = 9, double iconSize = 10}) {
    final color = getColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getIcon(platform, size: iconSize, color: color),
          const SizedBox(width: 4),
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
