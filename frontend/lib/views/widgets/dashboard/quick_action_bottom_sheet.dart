import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/game.dart';
import '../app_cover_image.dart';
import '../status_helper.dart';

/// Modal bottom sheet para interacciones y cambios de estado rápidos sobre un videojuego
class QuickActionBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required Game game,
    required ValueChanged<num> onAddHours,
    required ValueChanged<String> onStatusChange,
    required VoidCallback onEditDetails,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF27272A)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppCoverImage(
                        coverUrl: game.coverUrl,
                        width: 44,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFAFAFA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${game.platform ?? 'Sin plataforma'} • ${game.hoursPlayed ?? 0}h jugadas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 8),
                Text(
                  'Cambiar Estado',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA1A1AA),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusQuickButton(
                      ctx: ctx,
                      game: game,
                      status: StatusHelper.porJugar,
                      color: StatusHelper.getColor(StatusHelper.porJugar),
                      onStatusChange: onStatusChange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(
                      ctx: ctx,
                      game: game,
                      status: StatusHelper.jugando,
                      color: StatusHelper.getColor(StatusHelper.jugando),
                      onStatusChange: onStatusChange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(
                      ctx: ctx,
                      game: game,
                      status: StatusHelper.jugado,
                      color: StatusHelper.getColor(StatusHelper.jugado),
                      onStatusChange: onStatusChange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.timer_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Registrar sesión (+1 hora)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFAFAFA),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAddHours(1);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFAFAFA),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Ver detalle / Editar ficha',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFAFAFA),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEditDetails();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildStatusQuickButton({
    required BuildContext ctx,
    required Game game,
    required String status,
    required Color color,
    required ValueChanged<String> onStatusChange,
  }) {
    final isCurrent = game.status == status;
    return Expanded(
      child: InkWell(
        onTap: isCurrent
            ? null
            : () {
                Navigator.pop(ctx);
                onStatusChange(status);
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent ? color.withOpacity(0.2) : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent ? color : const Color(0xFF27272A),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? color : const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }
}

