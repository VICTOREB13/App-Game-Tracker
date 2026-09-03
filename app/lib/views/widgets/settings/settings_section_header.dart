import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Encabezado estándar para secciones de configuración
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDC2626),
        letterSpacing: 0.5,
      ),
    );
  }
}
