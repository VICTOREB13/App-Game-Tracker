import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game.dart';
import '../../services/theme_manager.dart';
import '../app_cover_image.dart';
import '../platform_helper.dart';

/// Tarjeta de cuadrícula con efecto hover, feedback táctil al presionar,
/// indicador de estado con resplandor y micro-barra de progreso HLTB.
class GameCardGrid extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GameCardGrid({
    super.key,
    required this.game,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<GameCardGrid> createState() => _GameCardGridState();
}

class _GameCardGridState extends State<GameCardGrid> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    Color statusColor;
    switch (game.status) {
      case 'Jugando':
        statusColor = const Color(0xFFDC2626);
        break;
      case 'Por jugar':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'Jugado':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFFA1A1AA);
    }

    final hours = game.hoursPlayed ?? 0;
    final hltb = game.hltbMain ?? 0;
    final progress = hltb > 0 ? (hours / hltb).clamp(0.0, 1.0) : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFFDC2626).withOpacity(0.7)
                    : AppColors.border(context),
                width: _isHovered ? 1.2 : 1,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  )
                else if (Theme.of(context).brightness == Brightness.dark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with Hero
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'game-cover-${game.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13)),
                          child: AnimatedScale(
                            scale: _isHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: AppCoverImage(
                              coverUrl: game.coverUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              memCacheHeight: 600,
                              cacheWidth: 400,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay at bottom of image
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.surface(context)
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Status indicator - top right dot with glow
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Rating pill if available
                      if (game.rating != null && game.rating!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF09090B).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.5),
                                  width: 0.5),
                            ),
                            child: Text(
                              game.rating!,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ),
                      // Micro-progress bar at bottom of cover if HLTB available
                      if (hltb > 0 && hours > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, animProg, _) {
                              return LinearProgressIndicator(
                                value: animProg,
                                minHeight: 3,
                                backgroundColor: Colors.transparent,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: _isHovered
                              ? const Color(0xFFDC2626)
                              : AppColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (game.platform != null &&
                                    game.platform!.isNotEmpty) ...[
                                  PlatformHelper.getIcon(game.platform!,
                                      size: 12),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    game.platform ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA1A1AA),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            status: game.status,
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge reutilizable para el estado del juego
class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
