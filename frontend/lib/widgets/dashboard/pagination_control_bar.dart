import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/theme_manager.dart';

/// Barra de control de paginación desacoplada y responsiva con selector de
/// elementos por página y zona de seguridad para evitar colisiones con el FAB.
class PaginationControlBar extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const PaginationControlBar({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 0.8),
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Items per page dropdown (Left side)
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
          ),

          // Center Spacer
          const Spacer(),

          // Navigation controls (Centered)
          if (pageSize > 0 && totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: currentPage > 1
                      ? AppColors.textPrimary(context)
                      : AppColors.textMuted(context),
                  onPressed:
                      currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
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
          else
            Text(
              '$totalItems juegos en total',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),

          // Right Spacer to keep navigation centered
          const Spacer(),

          // Dedicated safety zone: ensures FloatingActionButton NEVER overlaps pagination controls
          SizedBox(width: isMobile ? 64 : 100),
        ],
      ),
    );
  }
}
