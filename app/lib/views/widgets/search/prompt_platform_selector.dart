import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';
import '../platform_helper.dart';

/// Selector inteligente de plataformas con soporte para recomendadas por RAWG
/// y selector desplegable del catálogo completo de plataformas.
class PromptPlatformSelector extends StatefulWidget {
  final String selectedPlatform;
  final List<String> detectedPlatforms;
  final ValueChanged<String> onPlatformChanged;

  const PromptPlatformSelector({
    super.key,
    required this.selectedPlatform,
    required this.detectedPlatforms,
    required this.onPlatformChanged,
  });

  @override
  State<PromptPlatformSelector> createState() => _PromptPlatformSelectorState();
}

class _PromptPlatformSelectorState extends State<PromptPlatformSelector> {
  bool _showAllPlatforms = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasRecommended = widget.detectedPlatforms.isNotEmpty;

    final listToRender = _showAllPlatforms || !hasRecommended
        ? PlatformHelper.getOrderedPlatforms(
            recommended: widget.detectedPlatforms,
            currentPlatform: widget.selectedPlatform,
          )
        : [
            if (!widget.detectedPlatforms.contains(widget.selectedPlatform))
              widget.selectedPlatform,
            ...widget.detectedPlatforms,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Text(
                  'Plataforma',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                if (hasRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${widget.detectedPlatforms.length} recomendadas',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasRecommended)
              TextButton(
                onPressed: () =>
                    setState(() => _showAllPlatforms = !_showAllPlatforms),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  _showAllPlatforms
                      ? 'Solo recomendadas'
                      : '+ Otras plataformas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: listToRender.map((p) {
            final isSelected = widget.selectedPlatform == p;
            return InkWell(
              onTap: () => widget.onPlatformChanged(p),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFDC2626).withOpacity(0.15)
                      : (isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFF4F4F5)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFDC2626)
                        : (isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE4E4E7)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlatformHelper.getIcon(p, size: 15, isColor: isSelected),
                    const SizedBox(width: 7),
                    Text(
                      p,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFDC2626)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: Color(0xFFDC2626)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

