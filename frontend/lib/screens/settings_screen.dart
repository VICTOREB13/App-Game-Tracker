import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notion_service.dart';
import '../services/theme_manager.dart';
import '../services/backup_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notion = NotionService.instance;
  final _rawgKeyController = TextEditingController();
  bool _isConnected = false;
  String _dbId = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isConnected = _notion.isConfigured;
      _dbId = _notion.gamesDbId;
      _rawgKeyController.text = prefs.getString('rawg_key') ?? '';
    });
  }

  Future<void> _saveRawgKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rawg_key', _rawgKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RAWG API Key guardada con éxito',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _clearCache() {
    _notion.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caché local limpiado',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border(context)),
        ),
        title: Text(
          '¿Desconectar Notion?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        content: Text(
          'Se eliminarán las credenciales locales de Notion guardadas en este dispositivo.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary(context),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Desconectar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notion_token');
    await prefs.remove('notion_games_db_id');
    _notion.clearCache();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _editConnection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
    if (result == true) {
      _loadSettings();
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
              // Apariencia y Tema (Modo Claro / Modo Oscuro)
              _buildSectionHeader('Apariencia & Tema'),
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
                          'Selecciona el tema de la aplicación:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
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

              // Conexión Notion
              _buildSectionHeader('Conexión Notion'),
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
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isConnected ? 'Conectado a Notion' : 'Desconectado',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    if (_isConnected) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ID Base de Datos: ${_dbId.length > 16 ? '${_dbId.substring(0, 16)}...' : _dbId}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _editConnection,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Editar Conexión',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _disconnect,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFDC2626), width: 0.8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Desconectar',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // RAWG API Key
              _buildSectionHeader('Búsqueda de Juegos (RAWG)'),
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
                'Permite autocompletar carátulas, géneros y plataformas al añadir juegos. Obtén una gratis en rawg.io/apidocs',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 32),

              // Copia de Seguridad & Portabilidad (JSON)
              _buildSectionHeader('Copia de Seguridad & Portabilidad'),
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
                      'Respalda toda tu biblioteca en un archivo JSON seguro o restaura una copia previa en cualquier dispositivo.',
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
              const SizedBox(height: 32),

              // Cache & Offline
              _buildSectionHeader('Almacenamiento Local & Caché'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.cleaning_services_rounded,
                      size: 18, color: Color(0xFFDC2626)),
                  label: Text(
                    'Vaciar Caché Local',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // App info branding
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
                      'Rastreador de Entretenimiento Personal • v2.8.3',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sincronizado vía Notion API directa',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted(context),
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
          duration: const Duration(milliseconds: 180),
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
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al exportar respaldo: $e'),
          backgroundColor: const Color(0xFFDC2626),
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
                  Text(
                    'Selecciona un archivo de respaldo encontrado en tu carpeta de Descargas o pega la ruta/contenido JSON:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (availableBackups.isNotEmpty) ...[
                    Text(
                      'Respaldos recientes encontrados:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableBackups.take(4).map((file) {
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined,
                                    size: 18, color: Color(0xFFDC2626)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: Color(0xFFA1A1AA)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    'O especifica una ruta o contenido JSON:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'C:\\ruta\\al\\archivo.json o contenido {...}',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceSubtle(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary(context)),
              ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ¡Éxito! Se restauraron $count juegos en la biblioteca.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al restaurar: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _processJsonStringImport(String jsonStr) async {
    try {
      final count = await BackupService.importBackupFromJsonString(jsonStr);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ¡Éxito! Se restauraron $count juegos en la biblioteca.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al restaurar: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }
}

