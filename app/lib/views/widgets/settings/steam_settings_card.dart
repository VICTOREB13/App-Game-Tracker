import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de configuración para credenciales y sincronización de Steam
class SteamSettingsCard extends StatelessWidget {
  final TextEditingController steamKeyController;
  final TextEditingController steamIdController;
  final bool isTestingSteam;
  final bool isSyncingSteam;
  final VoidCallback onSave;
  final VoidCallback onResolveVanity;
  final VoidCallback onTestConnection;
  final VoidCallback onSyncNow;

  const SteamSettingsCard({
    super.key,
    required this.steamKeyController,
    required this.steamIdController,
    required this.isTestingSteam,
    required this.isSyncingSteam,
    required this.onSave,
    required this.onResolveVanity,
    required this.onTestConnection,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: steamKeyController,
            obscureText: true,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              labelText: 'Steam Web API Key',
              hintText: 'Clave de 32 caracteres',
              prefixIcon: const Icon(
                Icons.vpn_key_outlined,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save_rounded, color: Color(0xFFDC2626)),
                onPressed: onSave,
                tooltip: 'Guardar clave',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: steamIdController,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              labelText: 'SteamID64 o Vanity URL',
              hintText: '76561198... o tu apodo de perfil',
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, color: Color(0xFFDC2626)),
                onPressed: onResolveVanity,
                tooltip: 'Resolver Vanity URL a ID64',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soporta juegos propios y Family Sharing con detección de horas y auto-culminación HLTB.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isTestingSteam ? null : onTestConnection,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isTestingSteam
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Probar Conexión',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSyncingSteam ? null : onSyncNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: isSyncingSteam
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sincronizar Ahora',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

