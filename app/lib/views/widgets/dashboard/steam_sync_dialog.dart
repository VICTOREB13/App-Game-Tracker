import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/steam_service.dart';
import '../../../services/theme_manager.dart';
import '../status_helper.dart';

/// Diálogo de sincronización interactivo y reactivo con Steam,
/// conectado en tiempo real al progreso de escaneo, guardado en SQLite
/// y enriquecimiento de metadatos (HLTB, RAWG, Wikipedia).
class SteamSyncDialog extends StatefulWidget {
  final String apiKey;
  final String steamId;
  final bool importUnder30Min;

  const SteamSyncDialog({
    super.key,
    required this.apiKey,
    required this.steamId,
    this.importUnder30Min = false,
  });

  static Future<SteamSyncResult?> show({
    required BuildContext context,
    required String apiKey,
    required String steamId,
    bool importUnder30Min = false,
  }) {
    return showDialog<SteamSyncResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SteamSyncDialog(
        apiKey: apiKey,
        steamId: steamId,
        importUnder30Min: importUnder30Min,
      ),
    );
  }

  @override
  State<SteamSyncDialog> createState() => _SteamSyncDialogState();
}

class _SteamSyncDialogState extends State<SteamSyncDialog> {
  SyncProgress? _currentProgress;
  SteamSyncResult? _result;
  String? _errorMessage;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      final res = await SteamService.instance.syncWithDatabase(
        apiKey: widget.apiKey,
        steamId: widget.steamId,
        importUnder30Min: widget.importUnder30Min,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _currentProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isFinished = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isFinished = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playingColor = StatusHelper.getColor(StatusHelper.jugando);
    final completedColor = StatusHelper.getColor(StatusHelper.jugado);

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          Icon(
            _errorMessage != null
                ? Icons.error_outline_rounded
                : (_isFinished
                    ? Icons.check_circle_outline_rounded
                    : Icons.sync_rounded),
            color: _errorMessage != null
                ? playingColor
                : (_isFinished
                    ? completedColor
                    : playingColor),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage != null
                  ? 'Error de Sincronización'
                  : (_isFinished
                      ? 'Sincronización Completada'
                      : 'Sincronizando con Steam'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                'Ocurrió un error durante la sincronización:',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
            ] else if (!_isFinished) ...[
              Text(
                _currentProgress?.message ??
                    'Iniciando conexión con la API de Steam...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentProgress != null &&
                          _currentProgress!.total > 0)
                      ? _currentProgress!.progressPercentage
                      : null,
                  backgroundColor: AppColors.border(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFDC2626)),
                  minHeight: 6,
                ),
              ),
              if (_currentProgress != null &&
                  _currentProgress!.total > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentProgress?.currentGameTitle != null)
                      Expanded(
                        child: Text(
                          _currentProgress!.currentGameTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentProgress!.current}/${_currentProgress!.total} (${(_currentProgress!.progressPercentage * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (_result != null) ...[
              Text(
                'Resultado del escaneo en Steam:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 10),
              _buildSyncRow(
                  '🎮 Juegos detectados:', '${_result!.totalFound}'),
              _buildSyncRow(
                  '🔄 Horas actualizadas:', '${_result!.updatedCount}'),
              _buildSyncRow(
                  '✨ Títulos nuevos añadidos:', '${_result!.createdCount}'),
              if (_result!.familySharingCount > 0)
                _buildSyncRow('👨‍👩‍👧‍👦 Family Sharing detectados:',
                    '${_result!.familySharingCount}'),
              if (_result!.autoCulminatedCount > 0)
                _buildSyncRow('🏆 Auto-culminados por HLTB:',
                    '${_result!.autoCulminatedCount}'),
            ],
          ],
        ),
      ),
      actions: [
        if (_isFinished)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _result),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Entendido'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ocultar',
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
          ),
      ],
    );
  }

  Widget _buildSyncRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

