import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de configuración para RAWG API y sincronización masiva de metadatos
class RawgSettingsCard extends StatelessWidget {
  final TextEditingController rawgKeyController;
  final bool isSyncingMetadata;
  final VoidCallback onSave;
  final VoidCallback onSyncAllMetadata;

  const RawgSettingsCard({
    super.key,
    required this.rawgKeyController,
    required this.isSyncingMetadata,
    required this.onSave,
    required this.onSyncAllMetadata,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: rawgKeyController,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            labelText: 'RAWG API Key',
            hintText: 'Tu clave de rawg.io',
            prefixIcon: Icon(
              Icons.vpn_key_rounded,
              color: AppColors.textSecondary(context),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save_rounded, color: Color(0xFFDC2626)),
              onPressed: onSave,
              tooltip: 'Guardar clave RAWG',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permite autocompletar carátulas, géneros y enlaces enciclopédicos de Wikipedia. Obtén una gratis en rawg.io/apidocs',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncingMetadata ? null : onSyncAllMetadata,
            icon: isSyncingMetadata
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDC2626),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
            label: Text(
              isSyncingMetadata
                  ? 'Sincronizando Metadatos...'
                  : 'Sincronizar Géneros, Portadas y Wikipedia',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDC2626), width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

