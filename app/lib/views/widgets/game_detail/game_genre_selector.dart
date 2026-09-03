import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';
import '../genre_helper.dart';

/// Acordeón colapsable para la selección múltiple de géneros de un videojuego
class GameGenreSelector extends StatefulWidget {
  final List<String> selectedGenres;
  final ValueChanged<List<String>> onGenresChanged;

  const GameGenreSelector({
    super.key,
    required this.selectedGenres,
    required this.onGenresChanged,
  });

  @override
  State<GameGenreSelector> createState() => _GameGenreSelectorState();
}

class _GameGenreSelectorState extends State<GameGenreSelector> {
  bool _isExpanded = false;
  late final List<String> _availableGenres;

  @override
  void initState() {
    super.initState();
    _availableGenres = List.from(GenreHelper.allGenres);
    for (final g in widget.selectedGenres) {
      if (!_availableGenres.contains(g)) {
        _availableGenres.add(g);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded
              ? const Color(0xFFDC2626).withOpacity(0.5)
              : AppColors.border(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Text(
                        'Seleccionar Géneros',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.selectedGenres.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary(context),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableGenres.map((g) {
                  final isSelected = widget.selectedGenres.contains(g);
                  return FilterChip(
                    label: Text(
                      g,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textSecondary(context),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDC2626),
                    backgroundColor: AppColors.surfaceSubtle(context),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppColors.border(context),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    onSelected: (val) {
                      final updated = List<String>.from(widget.selectedGenres);
                      if (val) {
                        updated.add(g);
                      } else {
                        updated.remove(g);
                      }
                      widget.onGenresChanged(updated);
                    },
                  );
                }).toList(),
              ),
            ),
          ] else if (widget.selectedGenres.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedGenres.join(' • '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA1A1AA),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

