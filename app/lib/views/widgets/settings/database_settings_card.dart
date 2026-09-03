import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de configuración y diagnóstico de la base de datos local SQLite
class DatabaseSettingsCard extends StatelessWidget {
  final int gameCount;
  final double totalHours;
  final String dbPath;
  final VoidCallback onRefresh;
  final VoidCallback onOptimize;

  const DatabaseSettingsCard({
    super.key,
    required this.gameCount,
    required this.totalHours,
    required this.dbPath,
    required this.onRefresh,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Motor SQLite Activo (Local-First)',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: onRefresh,
                tooltip: 'Recargar métricas',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Biblioteca: $gameCount videojuegos registrados • ${totalHours.toStringAsFixed(1)} horas registradas',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          if (dbPath.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ruta: $dbPath',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOptimize,
            icon: const Icon(Icons.speed_rounded,
                size: 16, color: Color(0xFFDC2626)),
            label: Text(
              'Optimizar Base de Datos (Vacuum)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary(context),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

