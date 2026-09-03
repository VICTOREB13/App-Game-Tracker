import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';
import '../genre_helper.dart';

/// Acordeón interactivo colapsable para seleccionar géneros de videojuegos.
class PromptGenreSelector extends StatefulWidget {
  final List<String> selectedGenres;
  final List<String> availableGenres;
  final void Function(String genre, bool isSelected) onGenreToggled;

  const PromptGenreSelector({
    super.key,
    required this.selectedGenres,
    this.availableGenres = GenreHelper.allGenres,
    required this.onGenreToggled,
  });

  @override
  State<PromptGenreSelector> createState() => _PromptGenreSelectorState();
}

class _PromptGenreSelectorState extends State<PromptGenreSelector> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded
              ? const Color(0xFFDC2626).withOpacity(0.4)
              : AppColors.border(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Text(
                        'Géneros',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.selectedGenres.length}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.availableGenres.map((g) {
                  final isSelected = widget.selectedGenres.contains(g);
                  return FilterChip(
                    label: Text(
                      g,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary(context),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDC2626),
                    backgroundColor: AppColors.surface(context),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.border(context),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) =>
                        widget.onGenreToggled(g, selected),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

