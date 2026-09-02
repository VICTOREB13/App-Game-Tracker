import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game.dart';
import '../../services/theme_manager.dart';
import '../app_cover_image.dart';
import '../platform_helper.dart';

/// Tarjeta destacada cinemática para el juego en curso ("Jugando Ahora"),
/// con RepaintBoundary para aislar la animación continua del pulso a 60 FPS
/// sin invalidar el renderizado del resto del Dashboard.
class HeroSpotlightCard extends StatelessWidget {
  final Game game;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;
  final VoidCallback onQuickAddHours;

  const HeroSpotlightCard({
    super.key,
    required this.game,
    required this.pulseAnimation,
    required this.onTap,
    required this.onQuickAddHours,
  });

  @override
  Widget build(BuildContext context) {
    final hours = game.hoursPlayed ?? 0;
    final hltb = game.hltbMain ?? 0;
    final progress = hltb > 0 ? (hours / hltb).clamp(0.0, 1.0) : 0.0;
    final percentText = (progress * 100).toStringAsFixed(0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDC2626).withOpacity(isDark ? 0.35 : 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFDC2626).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle backdrop
          if (game.coverUrl != null && game.coverUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.15 : 0.07,
                child: AppCoverImage(
                  coverUrl: game.coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppCoverImage(
                      coverUrl: game.coverUrl,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      cacheWidth: 300,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFFDC2626)
                                        .withOpacity(0.4),
                                    width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // RepaintBoundary aísla la animación del pulso del resto de la UI
                                  RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFDC2626),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFDC2626)
                                                    .withOpacity(0.3 +
                                                        0.6 *
                                                            pulseAnimation
                                                                .value),
                                                blurRadius: 4 +
                                                    6 * pulseAnimation.value,
                                                spreadRadius: 1 +
                                                    1.5 * pulseAnimation.value,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'JUGANDO AHORA',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFDC2626),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (game.platform != null)
                              PlatformHelper.buildBadge(game.platform!),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Progress Bar & Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hltb > 0
                                  ? '${hours % 1 == 0 ? hours.toInt() : hours}h / ${hltb % 1 == 0 ? hltb.toInt() : hltb.toStringAsFixed(1)}h HLTB'
                                  : '${hours % 1 == 0 ? hours.toInt() : hours}h jugadas',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hltb > 0)
                              Text(
                                '$percentText%',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0.0,
                                end: progress.clamp(0.0, 1.0)),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, animProgress, child) {
                              return LinearProgressIndicator(
                                value: animProgress,
                                minHeight: 4,
                                backgroundColor: AppColors.border(context),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFDC2626)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Quick +1h button
                  ElevatedButton(
                    onPressed: onQuickAddHours,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(42, 42),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16),
                        Text(
                          '1h',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
