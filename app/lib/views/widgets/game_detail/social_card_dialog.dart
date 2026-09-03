import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/game.dart';
import '../../../services/string_normalizer.dart';
import '../../../services/theme_manager.dart';
import 'social_card_preview.dart';

/// Diálogo modal interactivo para previsualizar y exportar la tarjeta social en PNG
class SocialCardDialog {
  static Future<void> show({
    required BuildContext context,
    required Game game,
    required String title,
    required num hoursPlayed,
    required String rating,
    required String summary,
    required String platform,
    required String status,
    DateTime? completedDate,
    String? coverUrl,
  }) {
    final isCurrentDark = Theme.of(context).brightness == Brightness.dark;
    bool cardIsDark = isCurrentDark;
    bool isExporting = false;
    final GlobalKey cardKey = GlobalKey();

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.border(context), width: 1),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.share_rounded,
                                size: 16, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tarjeta Social de Reseña',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => setDialogState(() => cardIsDark = false),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !cardIsDark ? const Color(0xFFDC2626) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.light_mode_rounded,
                                          size: 12,
                                          color: !cardIsDark ? Colors.white : AppColors.textSecondary(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Claro',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: !cardIsDark ? Colors.white : AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setDialogState(() => cardIsDark = true),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cardIsDark ? const Color(0xFFDC2626) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.dark_mode_rounded,
                                          size: 12,
                                          color: cardIsDark ? Colors.white : AppColors.textSecondary(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Oscuro',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: cardIsDark ? Colors.white : AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textSecondary(context)),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: cardKey,
                    child: SocialCardPreview(
                      title: title.isEmpty ? game.title : title,
                      platform: platform,
                      status: status,
                      hoursPlayed: hoursPlayed,
                      rating: rating,
                      summary: summary,
                      coverUrl: coverUrl ?? game.coverUrl,
                      completedDate: completedDate ?? game.completedDate,
                      isDark: cardIsDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cerrar',
                          style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isExporting
                            ? null
                            : () async {
                                setDialogState(() => isExporting = true);
                                await _exportSocialCard(
                                  context: context,
                                  cardKey: cardKey,
                                  title: title.isEmpty ? game.title : title,
                                  isDark: cardIsDark,
                                );
                                if (ctx.mounted) {
                                  setDialogState(() => isExporting = false);
                                  Navigator.pop(ctx);
                                }
                              },
                        icon: isExporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(
                          isExporting ? 'Exportando...' : 'Guardar PNG (Descargas)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _exportSocialCard({
    required BuildContext context,
    required GlobalKey cardKey,
    required String title,
    required bool isDark,
  }) async {
    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      String savePath = '';
      final modeSuffix = isDark ? 'Dark' : 'Light';
      final cleanTitle = StringNormalizer.sanitizeFilename(title);

      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        final downloadsDir = Directory('$userProfile\\Downloads');
        final filePath =
            '${downloadsDir.path}\\Resena_VE_${cleanTitle}_${modeSuffix}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        savePath = filePath;
      } else {
        final file = File('Resena_VE_${cleanTitle}_${modeSuffix}_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        savePath = file.path;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarjeta ($modeSuffix) exportada en Descargas: $savePath',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar tarjeta: $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}

