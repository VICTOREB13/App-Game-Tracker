import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Barra inferior integrada y responsiva que unifica los controles de paginación
/// y la acción rápida para añadir nuevos videojuegos a la biblioteca.
class PaginationControlBar extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onAddGame;

  const PaginationControlBar({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.onAddGame,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0 && onAddGame == null) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(
            top: BorderSide(color: AppColors.border(context), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.light ? 0.05 : 0.25,
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Selector de elementos por página (Izquierda)
            if (totalItems > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMobile ? 'Ver:' : 'Por pág:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSize,
                        dropdownColor: AppColors.surface(context),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.textSecondary(context),
                          size: 18,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 25, child: Text('25')),
                          DropdownMenuItem(value: 50, child: Text('50')),
                          DropdownMenuItem(value: 100, child: Text('100')),
                          DropdownMenuItem(value: -1, child: Text('Todos')),
                        ],
                        onChanged: (val) {
                          if (val != null) onPageSizeChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Sin videojuegos',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),

            // Espaciador izquierdo
            const Spacer(),

            // Controles de navegación de página (Centro)
            if (totalItems > 0 && pageSize > 0 && totalPages > 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    color: currentPage > 1
                        ? AppColors.textPrimary(context)
                        : AppColors.textMuted(context),
                    onPressed: currentPage > 1
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    tooltip: 'Página anterior',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      '$currentPage / $totalPages',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    color: currentPage < totalPages
                        ? AppColors.textPrimary(context)
                        : AppColors.textMuted(context),
                    onPressed: currentPage < totalPages
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    tooltip: 'Página siguiente',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              )
            else if (totalItems > 0)
              Text(
                '$totalItems ${totalItems == 1 ? "juego" : "juegos"}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),

            // Espaciador derecho
            const Spacer(),

            // Botón de acción integrada: "+ Añadir juego" (Derecha)
            if (onAddGame != null)
              isMobile
                  ? Tooltip(
                      message: 'Añadir juego',
                      child: InkWell(
                        onTap: onAddGame,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onAddGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        'Añadir juego',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

