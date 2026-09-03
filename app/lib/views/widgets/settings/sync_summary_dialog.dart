import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Diálogo modal unificado para presentar resúmenes de sincronización
/// (Steam, HowLongToBeat, RAWG / Metadatos).
class SyncSummaryDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? message;
  final List<String> details;
  final String buttonText;

  const SyncSummaryDialog({
    super.key,
    required this.title,
    this.icon = Icons.check_circle_rounded,
    this.iconColor = const Color(0xFF10B981),
    this.message,
    this.details = const [],
    this.buttonText = 'Aceptar',
  });

  /// Muestra el diálogo en el contexto provisto.
  static Future<void> show({
    required BuildContext context,
    required String title,
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xFF10B981),
    String? message,
    List<String> details = const [],
    String buttonText = 'Aceptar',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => SyncSummaryDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        message: message,
        details: details,
        buttonText: buttonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null && message!.isNotEmpty) ...[
              Text(
                message!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary(context),
                  height: 1.4,
                ),
              ),
              if (details.isNotEmpty) const SizedBox(height: 12),
            ],
            if (details.isNotEmpty) ...[
              if (message == null)
                Text(
                  'Resumen:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              const SizedBox(height: 8),
              ...details.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

