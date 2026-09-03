import 'package:flutter/material.dart';

import '../../../models/game.dart';
import '../filter_modal_sheet.dart';
import '../genre_helper.dart';
import '../platform_helper.dart';

/// Helper para el cálculo eficiente de opciones y conteos de filtros
class FilterMetadataHelper {
  static List<FilterOption> buildPlatformOptions(List<Game> games) {
    final Map<String, int> counts = {};
    for (final g in games) {
      final p = g.platform?.trim();
      if (p != null && p.isNotEmpty) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return sorted
        .map((name) => FilterOption(
              label: name,
              count: counts[name] ?? 0,
              icon: PlatformHelper.getIcon(name, size: 16, isColor: true),
              color: const Color(0xFFDC2626),
            ))
        .toList();
  }

  static List<FilterOption> buildGenreOptions(List<Game> games) {
    final Map<String, int> counts = {};
    for (final g in games) {
      final normalized = g.genres
          .where((gen) => gen.trim().isNotEmpty)
          .map(GenreHelper.normalize)
          .toSet();
      for (final norm in normalized) {
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return sorted
        .map((name) => FilterOption(
              label: name,
              count: counts[name] ?? 0,
              icon: Icon(
                GenreHelper.getIcon(name),
                size: 16,
                color: GenreHelper.getColor(name),
              ),
              color: GenreHelper.getColor(name),
            ))
        .toList();
  }
}

