import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Diálogo modal para restaurar copias de seguridad de la biblioteca desde
/// archivos JSON locales, archivos de muestra o cadenas JSON crudas.
class ImportBackupDialog extends StatefulWidget {
  final List<File> availableBackups;
  final Future<void> Function(File file) onImportFile;
  final Future<void> Function(String jsonStr) onImportJsonString;

  const ImportBackupDialog({
    super.key,
    required this.availableBackups,
    required this.onImportFile,
    required this.onImportJsonString,
  });

  /// Muestra el diálogo en el contexto provisto.
  static Future<void> show({
    required BuildContext context,
    required List<File> availableBackups,
    required Future<void> Function(File file) onImportFile,
    required Future<void> Function(String jsonStr) onImportJsonString,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ImportBackupDialog(
        availableBackups: availableBackups,
        onImportFile: onImportFile,
        onImportJsonString: onImportJsonString,
      ),
    );
  }

  @override
  State<ImportBackupDialog> createState() => _ImportBackupDialogState();
}

class _ImportBackupDialogState extends State<ImportBackupDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFileFromDisk() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        if (!mounted) return;
        Navigator.pop(context);
        await widget.onImportFile(File(result.files.single.path!));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _loadSampleFile() async {
    Navigator.pop(context);
    final sampleFile = File('sample_games_library.json');
    if (await sampleFile.exists()) {
      await widget.onImportFile(sampleFile);
    } else {
      final alt = File('..\\sample_games_library.json');
      if (await alt.exists()) {
        await widget.onImportFile(alt);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('sample_games_library.json no encontrado'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _submitManualInput() async {
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    Navigator.pop(context);
    if (input.startsWith('{') || input.startsWith('[')) {
      await widget.onImportJsonString(input);
    } else {
      await widget.onImportFile(File(input));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickFileFromDisk,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(
                    'Elegir archivo JSON (Explorador)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadSampleFile,
                  icon: const Icon(Icons.science_outlined,
                      size: 16, color: Color(0xFFDC2626)),
                  label: Text(
                    'Cargar Datos de Prueba (sample_games_library.json)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.availableBackups.isNotEmpty) ...[
                Text(
                  'Respaldos en Descargas:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.availableBackups.take(3).map((file) {
                  final name = file.path.split(Platform.pathSeparator).last;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await widget.onImportFile(file);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
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
                                size: 10, color: Color(0xFFA1A1AA)),
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
                controller: _textController,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: 'C:\\ruta\\backup.json o {"games": [...]}',
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _submitManualInput,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
          child: const Text('Restaurar'),
        ),
      ],
    );
  }
}

