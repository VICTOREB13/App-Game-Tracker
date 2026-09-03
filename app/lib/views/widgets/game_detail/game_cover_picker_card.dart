import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../services/theme_manager.dart';
import '../app_cover_image.dart';

/// Tarjeta para la selección de carátula local con FilePicker y campo unificado de URL
class GameCoverPickerCard extends StatelessWidget {
  final TextEditingController coverUrlController;
  final String gameId;
  final VoidCallback onCoverChanged;

  const GameCoverPickerCard({
    super.key,
    required this.coverUrlController,
    required this.gameId,
    required this.onCoverChanged,
  });

  Future<void> _pickLocalImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (result != null && result.files.single.path != null) {
        final pickedFilePath = result.files.single.path!;
        final pickedFile = File(pickedFilePath);

        final appDir = await getApplicationDocumentsDirectory();
        final coversDir = Directory(p.join(appDir.path, 'covers'));
        if (!await coversDir.exists()) {
          await coversDir.create(recursive: true);
        }

        final ext = p.extension(pickedFilePath).toLowerCase();
        final destName = 'cover_${gameId}_${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(coversDir.path, destName);

        await pickedFile.copy(destPath);
        coverUrlController.text = destPath;
        onCoverChanged();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Imagen de portada seleccionada'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              AppCoverImage(
                coverUrl: coverUrlController.text,
                width: 50,
                height: 68,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalizar carátula',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa una URL web o sube un archivo directamente desde tu disco.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickLocalImage(context),
                      icon: const Icon(Icons.photo_library_rounded,
                          size: 16, color: Color(0xFFDC2626)),
                      label: Text(
                        'Elegir de mi Galería / Disco',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: coverUrlController,
            onChanged: (_) => onCoverChanged(),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              labelText: 'URL web de portada (o ruta local)',
              hintText: 'https://ejemplo.com/portada.jpg',
              prefixIcon: const Icon(Icons.image_outlined, size: 18, color: Color(0xFFDC2626)),
              suffixIcon: coverUrlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        coverUrlController.clear();
                        onCoverChanged();
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

