import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Campo de texto de búsqueda estilizado con iconos, clear reactivo y spinner
class SearchBarInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isSearching;
  final String hintText;

  const SearchBarInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
    required this.isSearching,
    this.hintText = 'Buscar juego en RAWG (ej: Elden Ring, Hollow Knight)...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary(context),
        ),
        suffixIcon: isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                ),
              )
            : IconButton(
                icon: Icon(Icons.clear, color: AppColors.textSecondary(context)),
                onPressed: onClear,
                tooltip: 'Limpiar búsqueda',
              ),
        filled: true,
        fillColor: AppColors.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
    );
  }
}

