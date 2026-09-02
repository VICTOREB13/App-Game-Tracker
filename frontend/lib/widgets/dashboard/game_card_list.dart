import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game.dart';
import '../../services/theme_manager.dart';
import '../app_cover_image.dart';
import '../platform_helper.dart';
import 'game_card_grid.dart';

/// Fila compacta de lista con soporte hover, feedback visual,
/// badge de estado, progreso HLTB y acción rápida (+1h).
class GameCardList extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onQuickAddHours;

  const GameCardList({
    super.key,
    required this.game,
    required this.onTap,
    required this.onLongPress,
    required this.onQuickAddHours,
  });

  @override
  State<GameCardList> createState() => _GameCardListState();
}

class _GameCardListState extends State<GameCardList> {
  bool _isHovered = false;

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
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceSubtle(context)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFDC2626).withOpacity(0.5)
                  : AppColors.border(context),
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail cover with Hero
              Hero(
                tag: 'game-cover-${game.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AppCoverImage(
                    coverUrl: game.coverUrl,
                    width: 36,
                    height: 48,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    memCacheHeight: 300,
                    cacheWidth: 200,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Platform/Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isHovered
                            ? const Color(0xFFDC2626)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (game.platform != null &&
                            game.platform!.isNotEmpty) ...[
                          PlatformHelper.getIcon(game.platform!, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            game.platform!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusBadge(status: game.status, color: statusColor),
                        if (game.rating != null &&
                            game.rating!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            game.rating!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Hours / HLTB Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hltb > 0
                        ? '${hours % 1 == 0 ? hours.toInt() : hours}h / ${hltb % 1 == 0 ? hltb.toInt() : hltb.toStringAsFixed(1)}h'
                        : '${hours % 1 == 0 ? hours.toInt() : hours}h',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA1A1AA),
                    ),
                  ),
                  if (hltb > 0) ...[
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: const Color(0xFF27272A),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),

              // Quick +1h button
              InkWell(
                onTap: widget.onQuickAddHours,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '+1h',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
