import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de resultado individual para juegos devueltos por RAWG
class SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> rawgGame;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.rawgGame,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final genreNames = ((rawgGame['genres'] as List<dynamic>?) ?? [])
        .map((g) => (g as Map<String, dynamic>?)?['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .take(3)
        .join(' • ');

    final coverUrl = rawgGame['background_image']?.toString();
    final name = rawgGame['name']?.toString() ?? 'Sin nombre';
    final released = rawgGame['released']?.toString() ?? 'Sin fecha';

    return Card(
      color: AppColors.surface(context),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      placeholder: (_, __) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.surfaceSubtle(context),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.surfaceSubtle(context),
                        child: Icon(
                          Icons.gamepad_rounded,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceSubtle(context),
                      child: Icon(
                        Icons.gamepad_rounded,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      released,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    if (genreNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        genreNames,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

