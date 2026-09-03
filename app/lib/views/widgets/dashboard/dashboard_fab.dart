import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating Action Button responsivo para añadir videojuegos
class DashboardFab extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onPressed;

  const DashboardFab({
    super.key,
    required this.isMobile,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        tooltip: 'Añadir juego',
        child: const Icon(Icons.add_rounded, size: 28),
      );
    }
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFFDC2626),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Añadir',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
    );
  }
}
