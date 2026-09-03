import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Vista de estado inicial/vacío para la pantalla de búsqueda
class SearchEmptyState extends StatelessWidget {
  final String message;

  const SearchEmptyState({
    super.key,
    this.message = 'Escribe el nombre de un juego para buscar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            size: 64,
            color: AppColors.textSecondary(context).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

