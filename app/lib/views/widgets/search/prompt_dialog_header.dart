import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';
import '../app_cover_image.dart';

/// Cabecera modular y stateless para el modal de customización de videojuego RAWG.
class PromptDialogHeader extends StatelessWidget {
  final String title;
  final String? coverUrl;
  final String? releaseDate;
  final num? playtime;

  const PromptDialogHeader({
    super.key,
    required this.title,
    this.coverUrl,
    this.releaseDate,
    this.playtime,
  });

  /// Constructor factory a partir de un mapa de RAWG.
  factory PromptDialogHeader.fromRawg({
    Key? key,
    required Map<String, dynamic> rawgGame,
  }) {
    return PromptDialogHeader(
      key: key,
      title: rawgGame['name']?.toString() ?? 'Juego',
      coverUrl: rawgGame['background_image']?.toString(),
      releaseDate: rawgGame['released']?.toString(),
      playtime: rawgGame['playtime'] as num?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pTime = playtime;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCoverImage(
          coverUrl: coverUrl,
          width: 60,
          height: 80,
          borderRadius: BorderRadius.circular(10),
          memCacheWidth: 200,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                releaseDate != null
                    ? 'Lanzamiento: $releaseDate'
                    : 'Sin fecha de lanzamiento',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              if (pTime != null && pTime > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'HLTB estimado: ${pTime}h',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

