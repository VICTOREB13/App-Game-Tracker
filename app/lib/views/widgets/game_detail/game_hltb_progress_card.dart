import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de gamificación y progreso contra estimaciones de HowLongToBeat
class GameHltbProgressCard extends StatelessWidget {
  final num hoursPlayed;
  final num hltbMain;
  final num? hltbCompletionist;

  const GameHltbProgressCard({
    super.key,
    required this.hoursPlayed,
    required this.hltbMain,
    this.hltbCompletionist,
  });

  @override
  Widget build(BuildContext context) {
    if (hltbMain <= 0) return const SizedBox.shrink();

    final progress = (hoursPlayed / hltbMain).clamp(0.0, 1.0);
    final comp = hltbCompletionist ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = hoursPlayed >= hltbMain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de Campaña',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historia: ${hltbMain.toInt()}h',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
              if (comp > 0)
                Text(
                  '100% Completista: ${comp.toInt()}h',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              Text(
                isCompleted
                    ? 'Completado'
                    : 'Faltan ~${(hltbMain - hoursPlayed).clamp(0, 999).toStringAsFixed(0)}h',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

