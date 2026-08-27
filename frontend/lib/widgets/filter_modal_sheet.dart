import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/theme_manager.dart';

class FilterOption {
  final String label;
  final int count;
  final Widget? icon;
  final Color? color;

  const FilterOption({
    required this.label,
    required this.count,
    this.icon,
    this.color,
  });
}

class FilterModalSheet extends StatefulWidget {
  final String title;
  final String selectedValue;
  final List<FilterOption> options;
  final ValueChanged<String> onSelected;
  final String allLabel;

  const FilterModalSheet({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.allLabel = 'Todos',
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String selectedValue,
    required List<FilterOption> options,
    required ValueChanged<String> onSelected,
    String allLabel = 'Todos',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterModalSheet(
        title: title,
        selectedValue: selectedValue,
        options: options,
        onSelected: onSelected,
        allLabel: allLabel,
      ),
    );
  }

  @override
  State<FilterModalSheet> createState() => _FilterModalSheetState();
}

class _FilterModalSheetState extends State<FilterModalSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    // Total de juegos sumando las opciones o el de "Todos"
    final totalGames = widget.options.isNotEmpty
        ? widget.options.map((e) => e.count).fold(0, (a, b) => a + b)
        : 0;

    // Filtrar opciones por el buscador
    final filteredOptions = widget.options.where((opt) {
      if (_searchQuery.isEmpty) return true;
      return opt.label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de arrastre superior
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Cabecera con título y botón de cerrar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Selecciona una opción para filtrar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Buscador en vivo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar en ${widget.title.toLowerCase()}...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceSubtle(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Lista de Opciones
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shrinkWrap: true,
                  children: [
                    // Opción 'Todos / Todas'
                    if (_searchQuery.isEmpty) ...[
                      _buildOptionTile(
                        label: widget.allLabel,
                        count: totalGames,
                        isSelected: widget.selectedValue == widget.allLabel ||
                            widget.selectedValue == 'Todos' ||
                            widget.selectedValue == 'Todas',
                        icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                        accentColor: const Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 6),
                    ],

                    if (filteredOptions.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 36, color: textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No se encontraron coincidencias',
                                style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...filteredOptions.map((opt) {
                        final isSelected = widget.selectedValue == opt.label;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildOptionTile(
                            label: opt.label,
                            count: opt.count,
                            isSelected: isSelected,
                            icon: opt.icon,
                            accentColor: opt.color,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String label,
    required int count,
    required bool isSelected,
    Widget? icon,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final activeColor = accentColor ?? const Color(0xFFDC2626);

    return InkWell(
      onTap: () {
        widget.onSelected(label);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(isDark ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.6)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Icono con fondo temático
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.2)
                    : AppColors.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: icon ??
                  Icon(
                    Icons.category_rounded,
                    size: 16,
                    color: isSelected ? activeColor : textSecondary,
                  ),
            ),
            const SizedBox(width: 12),

            // Nombre de la opción
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : textPrimary,
                ),
              ),
            ),

            // Conteo de juegos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.2)
                    : AppColors.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? activeColor.withOpacity(0.4)
                      : AppColors.border(context),
                ),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : textSecondary,
                ),
              ),
            ),

            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 18, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }
}
