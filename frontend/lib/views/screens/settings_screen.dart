import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/settings_controller.dart';
import '../../services/backup_service.dart';
import '../../services/theme_manager.dart';
import '../widgets/settings/backup_settings_card.dart';
import '../widgets/settings/branding_footer.dart';
import '../widgets/settings/database_settings_card.dart';
import '../widgets/settings/hltb_settings_card.dart';
import '../widgets/settings/import_backup_dialog.dart';
import '../widgets/settings/rawg_settings_card.dart';
import '../widgets/settings/settings_section_header.dart';
import '../widgets/settings/steam_settings_card.dart';
import '../widgets/settings/sync_summary_dialog.dart';
import '../widgets/settings/theme_settings_card.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController? controller;

  const SettingsScreen({super.key, this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  final _rawgKeyController = TextEditingController();
  final _steamKeyController = TextEditingController();
  final _steamIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsController();
    _controller.addListener(_onControllerChanged);
    _initData();
  }

  Future<void> _initData() async {
    await _controller.loadSettings();
    if (!mounted) return;
    _rawgKeyController.text = _controller.rawgApiKey;
    _steamKeyController.text = _controller.steamApiKey;
    _steamIdController.text = _controller.steamUserId;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _rawgKeyController.dispose();
    _steamKeyController.dispose();
    _steamIdController.dispose();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showFeedback(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final color = isError
        ? const Color(0xFFDC2626)
        : (isWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveRawgKey() async {
    try {
      await _controller.saveRawgKey(_rawgKeyController.text.trim());
      _showFeedback('RAWG API Key guardada con éxito');
    } catch (e) {
      _showFeedback('Error guardando RAWG key: $e', isError: true);
    }
  }

  Future<void> _saveSteamSettings() async {
    try {
      await _controller.saveSteamSettings(
        apiKey: _steamKeyController.text.trim(),
        steamId: _steamIdController.text.trim(),
      );
      _showFeedback('Credenciales de Steam guardadas con éxito');
    } catch (e) {
      _showFeedback('Error guardando ajustes Steam: $e', isError: true);
    }
  }

  Future<void> _testSteamConnection() async {
    final key = _steamKeyController.text.trim();
    final id = _steamIdController.text.trim();
    if (key.isEmpty || id.isEmpty) {
      return _showFeedback('Ingresa tu Steam Web API Key y SteamID', isWarning: true);
    }
    final isValid = await _controller.testSteamConnection(apiKey: key, steamId: id);
    if (!mounted) return;
    _showFeedback(
      isValid ? '✅ Conexión con Steam validada exitosamente' : '❌ No se pudo conectar con Steam.',
      isError: !isValid,
    );
  }

  Future<void> _resolveSteamVanity() async {
    final key = _steamKeyController.text.trim();
    final idOrVanity = _steamIdController.text.trim();
    if (key.isEmpty || idOrVanity.isEmpty) {
      return _showFeedback('Ingresa primero la API Key y tu perfil', isWarning: true);
    }
    final resolved = await _controller.resolveSteamVanity(idOrVanity, apiKey: key);
    if (!mounted) return;
    if (resolved != null) {
      setState(() => _steamIdController.text = resolved);
      await _saveSteamSettings();
      _showFeedback('✅ SteamID64 detectado: $resolved');
    } else {
      _showFeedback('No se pudo resolver el nombre de Steam', isError: true);
    }
  }

  Future<void> _syncSteam() async {
    final key = _steamKeyController.text.trim();
    final id = _steamIdController.text.trim();
    if (key.isEmpty || id.isEmpty) {
      return _showFeedback('Guarda tus credenciales de Steam antes de sincronizar', isWarning: true);
    }
    try {
      final res = await _controller.syncSteam();
      if (!mounted) return;
      await SyncSummaryDialog.show(
        context: context,
        title: 'Sincronización con Steam',
        details: [
          '🎮 Juegos encontrados: ${res.totalFound}',
          '🔄 Actualizados: ${res.updatedCount}',
          '✨ Creados: ${res.createdCount}',
          if (res.familySharingCount > 0) '👨‍👩‍👧‍👦 Family Sharing: ${res.familySharingCount}',
          if (res.autoCulminatedCount > 0) '🏆 Auto-culminados por HLTB: ${res.autoCulminatedCount}',
        ],
      );
    } catch (e) {
      _showFeedback('Error en sincronización Steam: $e', isError: true);
    }
  }

  Future<void> _syncAllHltb() async {
    try {
      final stats = await _controller.syncAllHltb(onlyPending: true);
      if (!mounted) return;
      final enriched = stats['updated'] ?? 0;
      final autoCulminated = stats['auto_culminated'] ?? 0;
      if (enriched == 0 && autoCulminated == 0) {
        _showFeedback('Todos los juegos ya tienen metadatos de HLTB');
        return;
      }
      await SyncSummaryDialog.show(
        context: context,
        title: 'HowLongToBeat Sincronizado',
        message: 'Se enriquecieron $enriched videojuegos con duración de Campaña y Completista.',
        details: [
          if (autoCulminated > 0) '🏆 $autoCulminated juegos auto-culminados a "Jugado".',
        ],
        buttonText: 'Entendido',
      );
    } catch (e) {
      _showFeedback('Error en sincronización HLTB: $e', isError: true);
    }
  }

  Future<void> _syncAllMetadata() async {
    try {
      final stats = await _controller.syncAllMetadata(onlyPending: true);
      if (!mounted) return;
      await SyncSummaryDialog.show(
        context: context,
        title: 'Metadatos Sincronizados',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFDC2626),
        message: 'Se completaron los siguientes metadatos en tu biblioteca:',
        details: [
          '• 🏷️ Géneros RAWG: ${stats['genres_updated'] ?? 0}',
          '• 🌐 Wikipedia: ${stats['wiki_updated'] ?? 0}',
          '• 🖼️ Portadas: ${stats['covers_updated'] ?? 0}',
        ],
        buttonText: 'Entendido',
      );
    } catch (e) {
      _showFeedback('Error en sincronización de metadatos: $e', isError: true);
    }
  }

  Future<void> _handleImport(Future<int> Function() operation) async {
    try {
      final count = await operation();
      await _controller.loadSettings();
      _showFeedback('✅ ¡Éxito! Se restauraron $count juegos en SQLite.');
    } catch (e) {
      _showFeedback('❌ Error al restaurar: $e', isError: true);
    }
  }

  Future<void> _showImportDialog() async {
    final backups = await BackupService.getAvailableBackups();
    if (!mounted) return;
    await ImportBackupDialog.show(
      context: context,
      availableBackups: backups,
      onImportFile: (f) => _handleImport(() => _controller.importBackupFromFile(f)),
      onImportJsonString: (s) => _handleImport(() => _controller.importBackupFromJsonString(s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Configuración',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SettingsSectionHeader('Apariencia'),
              const SizedBox(height: 12),
              const ThemeSettingsCard(),
              const SizedBox(height: 32),
              const SettingsSectionHeader('Base de Datos Local (SQLite)'),
              const SizedBox(height: 12),
              DatabaseSettingsCard(
                gameCount: _controller.gameCount,
                totalHours: _controller.totalHours,
                dbPath: _controller.databasePath,
                onRefresh: _controller.loadSettings,
                onOptimize: () async {
                  await _controller.optimizeDatabase();
                  _showFeedback('Base de datos SQLite optimizada');
                },
              ),
              const SizedBox(height: 32),
              const SettingsSectionHeader('Sincronización con Steam'),
              const SizedBox(height: 12),
              SteamSettingsCard(
                steamKeyController: _steamKeyController,
                steamIdController: _steamIdController,
                isTestingSteam: _controller.isTestingSteam,
                isSyncingSteam: _controller.isSyncingSteam,
                onSave: _saveSteamSettings,
                onResolveVanity: _resolveSteamVanity,
                onTestConnection: _testSteamConnection,
                onSyncNow: _syncSteam,
              ),
              const SizedBox(height: 32),
              const SettingsSectionHeader('Búsqueda & Metadatos (RAWG)'),
              const SizedBox(height: 12),
              RawgSettingsCard(
                rawgKeyController: _rawgKeyController,
                isSyncingMetadata: _controller.isSyncingMetadata,
                onSave: _saveRawgKey,
                onSyncAllMetadata: _syncAllMetadata,
              ),
              const SizedBox(height: 32),
              const SettingsSectionHeader('Duración & Campaña (HowLongToBeat)'),
              const SizedBox(height: 12),
              HltbSettingsCard(
                isSyncingHltb: _controller.isSyncingHltb,
                onSyncAllHltb: _syncAllHltb,
              ),
              const SizedBox(height: 32),
              const SettingsSectionHeader('Copia de Seguridad & Portabilidad (JSON)'),
              const SizedBox(height: 12),
              BackupSettingsCard(
                onExportBackup: () async {
                  try {
                    final path = await _controller.exportBackup();
                    _showFeedback('✅ Respaldo guardado exitosamente:\n$path');
                  } catch (e) {
                    _showFeedback('❌ Error al exportar: $e', isError: true);
                  }
                },
                onImportBackup: _showImportDialog,
              ),
              const SizedBox(height: 48),
              const BrandingFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
