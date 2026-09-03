import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Subheader del Dashboard con contador de juegos, chip de búsqueda, toggle Grid/Lista y controles de zoom de cuadrícula
class DashboardViewHeader extends StatelessWidget {
  final int filteredGamesCount;
  final int totalGamesCount;
  final String searchQuery;
  final bool isGridView;
  final double gridCardExtent;
  final VoidCallback onToggleViewMode;
  final ValueChanged<double> onGridCardExtentChanged;

  const DashboardViewHeader({
    super.key,
    required this.filteredGamesCount,
    required this.totalGamesCount,
    required this.searchQuery,
    required this.isGridView,
    required this.gridCardExtent,
    required this.onToggleViewMode,
    required this.onGridCardExtentChanged,
  });

  String _getCardSizeLabel(double extent) {
    if (extent <= 180) return 'Compacto';
    if (extent <= 250) return 'Normal';
    if (extent <= 330) return 'Grande';
    return 'Enorme';
  }

  PopupMenuItem<double> _buildSizeMenuItem(
    BuildContext context,
    double value,
    String label,
    IconData icon,
  ) {
    final isSelected = (gridCardExtent - value).abs() < 25;
    return PopupMenuItem<double>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? const Color(0xFFDC2626)
                : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : AppColors.textPrimary(context),
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 14, color: Color(0xFFDC2626)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$filteredGamesCount de $totalGamesCount juegos',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFA1A1AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchQuery.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Filtro: "$searchQuery"',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: isGridView ? null : onToggleViewMode,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isGridView
                              ? const Color(0xFFDC2626)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 13,
                              color: isGridView
                                  ? Colors.white
                                  : AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Grid',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isGridView
                                    ? Colors.white
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: !isGridView ? null : onToggleViewMode,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !isGridView
                              ? const Color(0xFFDC2626)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.view_list_rounded,
                              size: 14,
                              color: !isGridView
                                  ? Colors.white
                                  : AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Lista',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: !isGridView
                                    ? Colors.white
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isGridView) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 14),
                        tooltip: 'Reducir tamaño de tarjetas (Ctrl -)',
                        splashRadius: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        color: gridCardExtent > 150
                            ? AppColors.textPrimary(context)
                            : AppColors.textSecondary(context).withOpacity(0.3),
                        onPressed: gridCardExtent > 150
                            ? () => onGridCardExtentChanged(gridCardExtent - 35)
                            : null,
                      ),
                      PopupMenuButton<double>(
                        tooltip: 'Tamaño de visualización (Estilo Windows)',
                        color: AppColors.surface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border(context)),
                        ),
                        onSelected: onGridCardExtentChanged,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_size_select_actual_outlined,
                                size: 13,
                                color: AppColors.textPrimary(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCardSizeLabel(gridCardExtent),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 14,
                                color: AppColors.textSecondary(context),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (ctx) => [
                          _buildSizeMenuItem(
                            context,
                            160.0,
                            'Iconos compactos (Pequeño)',
                            Icons.view_module_rounded,
                          ),
                          _buildSizeMenuItem(
                            context,
                            220.0,
                            'Iconos medianos (Normal)',
                            Icons.grid_view_rounded,
                          ),
                          _buildSizeMenuItem(
                            context,
                            290.0,
                            'Iconos grandes',
                            Icons.window_rounded,
                          ),
                          _buildSizeMenuItem(
                            context,
                            380.0,
                            'Iconos muy grandes (Detallado)',
                            Icons.crop_portrait_rounded,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 14),
                        tooltip: 'Aumentar tamaño de tarjetas (Ctrl +)',
                        splashRadius: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        color: gridCardExtent < 380
                            ? AppColors.textPrimary(context)
                            : AppColors.textSecondary(context).withOpacity(0.3),
                        onPressed: gridCardExtent < 380
                            ? () => onGridCardExtentChanged(gridCardExtent + 35)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

