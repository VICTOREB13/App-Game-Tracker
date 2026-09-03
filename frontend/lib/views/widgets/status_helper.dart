import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/theme_manager.dart';

/// Helper centralizado para la gestión y presentación de estados de videojuegos
class StatusHelper {
  static const String porJugar = 'Por jugar';
  static const String jugando = 'Jugando';
  static const String jugado = 'Jugado';

  /// Constantes en inglés como alias de conveniencia
  static const String playing = jugando;
  static const String backlog = porJugar;
  static const String completed = jugado;

  /// Lista maestra para filtros globales en vistas y dashboards
  static const List<String> allStatuses = [
    'Todos',
    jugando,
    porJugar,
    jugado,
  ];

  /// Lista de estados asignables a una entidad de juego
  static const List<String> gameStatuses = [
    porJugar,
    jugando,
    jugado,
  ];

  /// Obtiene el color distintivo asociado a un estado
  static Color getColor(String? status) {
    switch (status) {
      case jugando:
        return const Color(0xFFDC2626);
      case porJugar:
        return const Color(0xFFF59E0B);
      case jugado:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  /// Obtiene el icono representativo del estado
  static IconData getIcon(String? status) {
    switch (status) {
      case jugando:
        return Icons.play_circle_outline_rounded;
      case porJugar:
        return Icons.watch_later_outlined;
      case jugado:
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  /// Construye un pill visual formateado para encabezados y vistas de detalle
  static Widget buildStatusPill(
    BuildContext context,
    String? status, {
    double fontSize = 11,
  }) {
    final effectiveStatus = status ?? porJugar;
    final color = getColor(effectiveStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        effectiveStatus,
        style: GoogleFonts.inter(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Construye un FilterChip interactivo adaptado al tema actual
  static Widget buildStatusChip({
    required BuildContext context,
    required String status,
    required bool isSelected,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color chipColor = status == 'Todos'
        ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B))
        : getColor(status);

    return FilterChip(
      label: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark
                  ? chipColor
                  : (status == 'Todos'
                      ? AppColors.textPrimary(context)
                      : chipColor)),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(status),
      backgroundColor: AppColors.surfaceSubtle(context),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? chipColor
              : (isDark
                  ? const Color(0xFF27272A)
                  : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

/// Widget reutilizable tipo Badge para mostrar el estado de un juego en tarjetas y listas
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? StatusHelper.getColor(status);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: effectiveColor.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: effectiveColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

