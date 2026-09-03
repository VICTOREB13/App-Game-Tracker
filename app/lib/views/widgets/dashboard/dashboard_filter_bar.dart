import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';
import '../filter_modal_sheet.dart';
import '../genre_helper.dart';
import '../platform_helper.dart';
import '../status_helper.dart';

/// Barra de filtros adaptativa (2 filas móvil / 1 fila desktop) con chips y selectores modales
class DashboardFilterBar extends StatelessWidget {
  final String selectedStatus;
  final String selectedPlatform;
  final String selectedGenre;
  final String selectedSort;
  final List<String> statusFilters;
  final List<FilterOption> platformOptions;
  final List<FilterOption> genreOptions;
  final int activeFiltersCount;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onPlatformSelected;
  final ValueChanged<String> onGenreSelected;
  final ValueChanged<String> onSortSelected;
  final VoidCallback onClearFilters;

  const DashboardFilterBar({
    super.key,
    required this.selectedStatus,
    required this.selectedPlatform,
    required this.selectedGenre,
    required this.selectedSort,
    this.statusFilters = StatusHelper.allStatuses,
    required this.platformOptions,
    required this.genreOptions,
    required this.activeFiltersCount,
    required this.onStatusSelected,
    required this.onPlatformSelected,
    required this.onGenreSelected,
    required this.onSortSelected,
    required this.onClearFilters,
  });

  bool get isAnyFilterActive => activeFiltersCount > 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileFilter = screenWidth < 600;

    if (isMobileFilter) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: statusFilters
                    .map((status) => _buildFilterChip(context, status))
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPlatformFilterButton(context),
                  const SizedBox(width: 8),
                  _buildGenreFilterButton(context),
                  const SizedBox(width: 8),
                  _buildSortDropdown(context),
                  if (isAnyFilterActive) ...[
                    const SizedBox(width: 8),
                    _buildClearFiltersButton(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ...statusFilters.map((status) => _buildFilterChip(context, status)),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: AppColors.border(context),
            ),
            const SizedBox(width: 8),
            _buildPlatformFilterButton(context),
            const SizedBox(width: 8),
            _buildGenreFilterButton(context),
            const SizedBox(width: 8),
            _buildSortDropdown(context),
            if (isAnyFilterActive) ...[
              const SizedBox(width: 8),
              _buildClearFiltersButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    final isSelected = selectedStatus == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color chipColor = label == 'Todos'
        ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B))
        : StatusHelper.getColor(label);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? chipColor
                    : (label == 'Todos'
                        ? AppColors.textPrimary(context)
                        : chipColor)),
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onStatusSelected(label),
        selectedColor: chipColor,
        backgroundColor: isDark
            ? chipColor.withOpacity(0.12)
            : (isSelected ? chipColor : Colors.white),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark
                  ? chipColor.withOpacity(0.35)
                  : AppColors.border(context)),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
    );
  }

  Widget _buildPlatformFilterButton(BuildContext context) {
    final isFiltered = selectedPlatform != 'Todas';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FilterModalSheet.show(
          context: context,
          title: 'Plataformas',
          selectedValue: selectedPlatform,
          options: platformOptions,
          allLabel: 'Todas',
          onSelected: onPlatformSelected,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isFiltered
              ? const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFiltered
                ? const Color(0xFFDC2626)
                : AppColors.border(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFiltered) ...[
              PlatformHelper.getIcon(selectedPlatform, size: 14, isColor: true),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.videogame_asset_outlined,
                size: 14,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isFiltered ? selectedPlatform : 'Plataforma: Todas',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreFilterButton(BuildContext context) {
    final isFiltered = selectedGenre != 'Todos';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FilterModalSheet.show(
          context: context,
          title: 'Géneros',
          selectedValue: selectedGenre,
          options: genreOptions,
          allLabel: 'Todos',
          onSelected: onGenreSelected,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isFiltered
              ? const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFiltered
                ? const Color(0xFFDC2626)
                : AppColors.border(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? GenreHelper.getIcon(selectedGenre)
                  : Icons.tune_rounded,
              size: 14,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              isFiltered ? selectedGenre : 'Género: Todos',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSort,
          dropdownColor: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textPrimary(context),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.sort_rounded,
              size: 16,
              color: AppColors.textSecondary(context),
            ),
          ),
          items: const ['Recientes', 'A-Z', 'Z-A', 'Horas (Mayor)', 'Calificación']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onSortSelected(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onClearFilters,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 4),
            Text(
              activeFiltersCount > 1
                  ? 'Limpiar ($activeFiltersCount)'
                  : 'Limpiar',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

