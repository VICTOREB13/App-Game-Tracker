import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../services/database_service.dart';
import '../services/steam_service.dart';
import '../services/theme_manager.dart';
import '../services/backup_service.dart';
import '../services/hltb_service.dart';
import '../services/metadata_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _rawgKeyController = TextEditingController();
  final _steamKeyController = TextEditingController();
  final _steamIdController = TextEditingController();

  int _gameCount = 0;
  double _totalHours = 0.0;
  String _dbPath = '';
  bool _isTestingSteam = false;
  bool _isSyncingSteam = false;
  bool _isSyncingHltb = false;
  bool _isSyncingMetadata = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _rawgKeyController.dispose();
    _steamKeyController.dispose();
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await DatabaseService.instance.getGameCount();
    final hours = await DatabaseService.instance.getTotalHours();
    final path = await DatabaseService.instance.getDatabasePath();

    setState(() {
      _rawgKeyController.text = prefs.getString('rawg_key') ?? '';
      _steamKeyController.text = prefs.getString('steam_api_key') ?? '';
      _steamIdController.text = prefs.getString('steam_user_id') ?? '';
      _gameCount = count;
      _totalHours = hours;
      _dbPath = path;
    });
  }

  Future<void> _saveRawgKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rawg_key', _rawgKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RAWG API Key guardada con éxito'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveSteamSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('steam_api_key', _steamKeyController.text.trim());
    await prefs.setString('steam_user_id', _steamIdController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales de Steam guardadas con éxito'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testSteamConnection() async {
    final key = _steamKeyController.text.trim();
    final id = _steamIdController.text.trim();

    if (key.isEmpty || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu Steam Web API Key y SteamID'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isTestingSteam = true);

    final isValid = await SteamService.instance.validateCredentials(key, id);

    if (mounted) {
      setState(() => _isTestingSteam = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid
              ? '✅ Conexión con Steam validada exitosamente'
              : '❌ No se pudo conectar con Steam. Verifica tu API Key y SteamID.'),
          backgroundColor: isValid ? const Color(0xFF10B981) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resolveSteamVanity() async {
    final key = _steamKeyController.text.trim();
    final idOrVanity = _steamIdController.text.trim();

    if (key.isEmpty || idOrVanity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa primero la API Key y tu nombre o enlace de perfil'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final resolved = await SteamService.instance.resolveVanityUrl(key, idOrVanity);
    if (resolved != null) {
      setState(() {
        _steamIdController.text = resolved;
      });
      await _saveSteamSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ SteamID64 detectado: $resolved'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo resolver el nombre de usuario de Steam'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _syncSteam() async {
    final key = _steamKeyController.text.trim();
    final id = _steamIdController.text.trim();

    if (key.isEmpty || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarda tus credenciales de Steam antes de sincronizar'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSyncingSteam = true);

    try {
      final res = await SteamService.instance.syncWithDatabase(apiKey: key, steamId: id);
      await _loadSettings();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border(context)),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Sincronización con Steam',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Text('🎮 Juegos encontrados: ${res.totalFound}', style: GoogleFonts.inter(fontSize: 12)),
                Text('🔄 Actualizados: ${res.updatedCount}', style: GoogleFonts.inter(fontSize: 12)),
                Text('✨ Creados: ${res.createdCount}', style: GoogleFonts.inter(fontSize: 12)),
                if (res.familySharingCount > 0)
                  Text('👨‍👩‍👧‍👦 Family Sharing: ${res.familySharingCount}', style: GoogleFonts.inter(fontSize: 12)),
                if (res.autoCulminatedCount > 0)
                  Text('🏆 Auto-culminados por HLTB: ${res.autoCulminatedCount}', style: GoogleFonts.inter(fontSize: 12)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingSteam = false);
    }
  }

  Future<void> _syncAllHltb() async {
    final db = DatabaseService.instance;
    final allGames = await db.getAllGames();
    final pending = allGames
        .where((g) =>
            (g.hltbMain == null || g.hltbMain == 0) ||
            (g.hltbCompletionist == null || g.hltbCompletionist == 0))
        .toList();

    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los juegos ya tienen metadatos de HowLongToBeat'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSyncingHltb = true);

    int enrichedCount = 0;
    int autoCulminatedCount = 0;

    for (int i = 0; i < pending.length; i++) {
      final game = pending[i];
      try {
        final result = await HltbService.instance.searchHltb(game.title);
        if (result != null &&
            (result.mainStory != null || result.completionist != null)) {
          final newMain = result.mainStory ?? game.hltbMain;
          final newComp = result.completionist ?? game.hltbCompletionist;

          String finalStatus = game.status;
          DateTime? finalCompleted = game.completedDate;

          final hours = game.hoursPlayed ?? 0;
          if (newMain != null &&
              newMain > 0 &&
              hours >= newMain &&
              game.status != 'Jugado') {
            finalStatus = 'Jugado';
            finalCompleted ??= DateTime.now();
            autoCulminatedCount++;
          }

          final updated = game.copyWith(
            hltbMain: newMain,
            hltbCompletionist: newComp,
            status: finalStatus,
            completedDate: finalCompleted,
            updatedAt: DateTime.now(),
          );

          await db.updateGame(updated);
          enrichedCount++;
        }
      } catch (e) {
        debugPrint('Error enriqueciendo HLTB (${game.title}): $e');
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _loadSettings();

    if (mounted) {
      setState(() => _isSyncingHltb = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text('HowLongToBeat Sincronizado',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'Se enriquecieron $enrichedCount videojuegos con duración de Campaña y Completista.\n'
            '${autoCulminatedCount > 0 ? "🏆 $autoCulminatedCount juegos auto-culminados a 'Jugado'." : ""}',
            style: GoogleFonts.inter(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _syncAllMetadata() async {
    final db = DatabaseService.instance;
    final allGames = await db.getAllGames();
    final rawgKey = _rawgKeyController.text.trim();

    final pending = allGames
        .where((g) =>
            g.genres.isEmpty ||
            (g.link == null || g.link!.trim().isEmpty) ||
            (g.coverUrl == null || g.coverUrl!.trim().isEmpty))
        .toList();

    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Todos los juegos ya tienen géneros, portada y enlace de Wikipedia'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSyncingMetadata = true);

    int genresUpdated = 0;
    int wikiUpdated = 0;
    int coversUpdated = 0;

    for (int i = 0; i < pending.length; i++) {
      final game = pending[i];
      bool modified = false;
      List<String> newGenres = List.from(game.genres);
      String? newCover = game.coverUrl;
      String? newLink = game.link;

      // 1. Wikipedia: si no tiene link oficial
      if (newLink == null || newLink.trim().isEmpty) {
        try {
          final wikiUrl =
              await MetadataService.instance.searchWikipedia(game.title);
          if (wikiUrl != null && wikiUrl.isNotEmpty) {
            newLink = wikiUrl;
            wikiUpdated++;
            modified = true;
          }
        } catch (_) {}
      }

      // 2. RAWG: géneros y portada si hay clave configurada
      if (rawgKey.isNotEmpty &&
          (newGenres.isEmpty || (newCover == null || newCover.isEmpty))) {
        try {
          final rawgData =
              await MetadataService.instance.searchRawg(game.title, rawgKey);
          if (rawgData != null) {
            if (newGenres.isEmpty &&
                rawgData['genres'] != null &&
                (rawgData['genres'] as List).isNotEmpty) {
              newGenres = List<String>.from(rawgData['genres']);
              genresUpdated++;
              modified = true;
            }
            if ((newCover == null || newCover.isEmpty) &&
                rawgData['cover_url'] != null) {
              newCover = rawgData['cover_url'];
              coversUpdated++;
              modified = true;
            }
          }
        } catch (_) {}
      }

      if (modified) {
        final updated = game.copyWith(
          genres: newGenres,
          coverUrl: newCover,
          link: newLink,
          updatedAt: DateTime.now(),
        );
        await db.updateGame(updated);
      }

      await Future.delayed(const Duration(milliseconds: 250));
    }

    await _loadSettings();

    if (mounted) {
      setState(() => _isSyncingMetadata = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text('Metadatos Sincronizados',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'Se completaron los siguientes metadatos en tu biblioteca:\n\n'
            '• 🏷️ Géneros RAWG asignados: $genresUpdated juegos\n'
            '• 🌐 Enlaces de Wikipedia: $wikiUpdated juegos\n'
            '• 🖼️ Portadas HD asignadas: $coversUpdated juegos',
            style: GoogleFonts.inter(fontSize: 13, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _optimizeDatabase() async {
    await DatabaseService.instance.vacuum();
    await _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base de datos SQLite optimizada'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              // Apariencia y Tema
              _buildSectionHeader('Apariencia'),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: ThemeManager.instance,
                builder: (context, _) {
                  final current = ThemeManager.instance.themeMode;
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
                        Text(
                          'Tema Visual',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildThemeOption(
                              label: 'Oscuro',
                              icon: Icons.dark_mode_rounded,
                              isSelected: current == ThemeMode.dark,
                              onTap: () => ThemeManager.instance
                                  .setThemeMode(ThemeMode.dark),
                            ),
                            const SizedBox(width: 10),
                            _buildThemeOption(
                              label: 'Claro',
                              icon: Icons.light_mode_rounded,
                              isSelected: current == ThemeMode.light,
                              onTap: () => ThemeManager.instance
                                  .setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 10),
                            _buildThemeOption(
                              label: 'Sistema',
                              icon: Icons.brightness_auto_rounded,
                              isSelected: current == ThemeMode.system,
                              onTap: () => ThemeManager.instance
                                  .setThemeMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Almacenamiento Local SQLite
              _buildSectionHeader('Base de Datos Local (SQLite)'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Motor SQLite Activo (Local-First)',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: _loadSettings,
                          tooltip: 'Recargar métricas',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Biblioteca: $_gameCount videojuegos registrados • ${_totalHours.toStringAsFixed(1)} horas registradas',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (_dbPath.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ruta: $_dbPath',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _optimizeDatabase,
                      icon: const Icon(Icons.speed_rounded, size: 16, color: Color(0xFFDC2626)),
                      label: Text(
                        'Optimizar Base de Datos (Vacuum)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Integración con Steam
              _buildSectionHeader('Sincronización con Steam'),
              const SizedBox(height: 12),
              Container(
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
                      controller: _steamKeyController,
                      obscureText: true,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Steam Web API Key',
                        hintText: 'Clave de 32 caracteres',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFFDC2626)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save_rounded, color: Color(0xFFDC2626)),
                          onPressed: _saveSteamSettings,
                          tooltip: 'Guardar clave',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _steamIdController,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'SteamID64 o Vanity URL',
                        hintText: '76561198... o tu apodo de perfil',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded, color: Color(0xFFDC2626)),
                          onPressed: _resolveSteamVanity,
                          tooltip: 'Resolver Vanity URL a ID64',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soporta juegos propios y Family Sharing con detección de horas y auto-culminación HLTB.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isTestingSteam ? null : _testSteamConnection,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isTestingSteam
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('Probar Conexión', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary(context))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSyncingSteam ? null : _syncSteam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: _isSyncingSteam
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Sincronizar Ahora', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // RAWG API Key
              _buildSectionHeader('Búsqueda & Metadatos (RAWG)'),
              const SizedBox(height: 12),
              TextField(
                controller: _rawgKeyController,
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
                    onPressed: _saveRawgKey,
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
                  onPressed: _isSyncingMetadata ? null : _syncAllMetadata,
                  icon: _isSyncingMetadata
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC2626),
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: Color(0xFFDC2626)),
                  label: Text(
                    _isSyncingMetadata
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
              const SizedBox(height: 32),

              // HowLongToBeat Integration & Bulk Enrichment
              _buildSectionHeader('Duración & Campaña (HowLongToBeat)'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timer_outlined,
                              size: 18, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sincronización HowLongToBeat',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Consulta la duración estimada de la Historia Principal y Completista al 100% directamente desde HowLongToBeat sin requerir API Keys. Habilita la auto-culminación inteligente cuando tus horas registradas alcanzan la duración de campaña.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncingHltb ? null : _syncAllHltb,
                        icon: _isSyncingHltb
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          _isSyncingHltb
                              ? 'Consultando HowLongToBeat...'
                              : 'Buscar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Copia de Seguridad & Portabilidad (JSON)
              _buildSectionHeader('Copia de Seguridad & Portabilidad (JSON)'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Respalda toda tu biblioteca en un archivo JSON seguro o restaura copias previas.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportBackup,
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: Text(
                              'Exportar JSON',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showImportDialog,
                            icon: const Icon(Icons.file_upload_outlined,
                                size: 18, color: Color(0xFFDC2626)),
                            label: Text(
                              'Importar JSON',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border(context)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Branding oficial Victor Engineer
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'VE',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Victor ',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              TextSpan(
                                text: 'Engineer',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gaming Tracker App • v3.0.6',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'https://victorengineer.fyi',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDC2626),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFDC2626)
                : AppColors.surfaceSubtle(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : AppColors.border(context),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      final path = await BackupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Respaldo guardado exitosamente:\n$path'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al exportar: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showImportDialog() async {
    final availableBackups = await BackupService.getAvailableBackups();
    final textController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.restore_page_rounded,
                  color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Text(
                'Restaurar Respaldo',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón directo para seleccionar archivo mediante FilePicker
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                          );
                          if (result != null && result.files.single.path != null) {
                            Navigator.pop(ctx);
                            await _processFileImport(File(result.files.single.path!));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)),
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(
                        'Elegir archivo JSON (Explorador)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón para cargar datos de prueba ficticios
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final sampleFile = File('sample_games_library.json');
                        if (await sampleFile.exists()) {
                          await _processFileImport(sampleFile);
                        } else {
                          // Buscar en Downloads o directorio actual
                          final alt = File('..\\sample_games_library.json');
                          if (await alt.exists()) {
                            await _processFileImport(alt);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('sample_games_library.json no encontrado'), backgroundColor: Color(0xFFDC2626)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.science_outlined, size: 16, color: Color(0xFFDC2626)),
                      label: Text(
                        'Cargar Datos de Prueba (sample_games_library.json)',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary(context)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (availableBackups.isNotEmpty) ...[
                    Text(
                      'Respaldos en Descargas:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableBackups.take(3).map((file) {
                      final name = file.path.split(Platform.pathSeparator).last;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _processFileImport(file);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFA1A1AA)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    'O pega la ruta o texto JSON:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textController,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'C:\\ruta\\backup.json o {"games": [...]}',
                      hintStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                      filled: true,
                      fillColor: AppColors.surfaceSubtle(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = textController.text.trim();
                if (input.isEmpty) return;
                Navigator.pop(ctx);
                if (input.startsWith('{') || input.startsWith('[')) {
                  await _processJsonStringImport(input);
                } else {
                  await _processFileImport(File(input));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processFileImport(File file) async {
    try {
      final count = await BackupService.importBackupFromFile(file);
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ¡Éxito! Se restauraron $count juegos en SQLite.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al restaurar: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processJsonStringImport(String jsonStr) async {
    try {
      final count = await BackupService.importBackupFromJsonString(jsonStr);
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ¡Éxito! Se restauraron $count juegos en SQLite.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al restaurar: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
