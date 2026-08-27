import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/game.dart';
import 'database_service.dart';

/// Servicio de enriquecimiento automático de metadatos (RAWG, Wikipedia y HLTB)
/// Replicación de `rellenar_metadata()` de `games.py`.
class MetadataService {
  static MetadataService? _instance;

  MetadataService._();

  static MetadataService get instance {
    _instance ??= MetadataService._();
    return _instance!;
  }

  /// Busca el enlace enciclopédico oficial en Wikipedia (probando español e inglés)
  Future<String?> searchWikipedia(String gameTitle) async {
    final searches = [
      {'lang': 'es', 'query': '$gameTitle videojuego'},
      {'lang': 'en', 'query': '$gameTitle video game'},
    ];

    for (final item in searches) {
      try {
        final lang = item['lang']!;
        final q = Uri.encodeComponent(item['query']!);
        final url = Uri.parse(
          'https://$lang.wikipedia.org/w/api.php?action=query&list=search&srsearch=$q&format=json&srlimit=1',
        );

        final res = await http
            .get(url, headers: {'User-Agent': 'GameTracker/3.0'})
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final searchResults = data['query']?['search'] as List?;
          if (searchResults != null && searchResults.isNotEmpty) {
            final title = searchResults[0]['title']?.toString() ?? '';
            if (title.isNotEmpty) {
              return 'https://$lang.wikipedia.org/wiki/${title.replaceAll(' ', '_')}';
            }
          }
        }
      } catch (e) {
        debugPrint('Error consultando Wikipedia ($gameTitle): $e');
      }
    }
    return null;
  }

  /// Busca metadatos en RAWG API (portada HD, géneros y tiempo estimado HLTB)
  Future<Map<String, dynamic>?> searchRawg(String gameTitle, String rawgKey) async {
    if (rawgKey.trim().isEmpty) return null;

    try {
      final encodedTitle = Uri.encodeComponent(gameTitle.trim());
      final url = Uri.parse(
        'https://api.rawg.io/api/games?key=${rawgKey.trim()}&search=$encodedTitle&page_size=1',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final match = results[0];
          final rawGenres = match['genres'] as List? ?? [];
          final genres = rawGenres
              .map((g) => g['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          return {
            'cover_url': match['background_image']?.toString(),
            'genres': genres,
            'hltb_main': (match['playtime'] as num?)?.toDouble(),
          };
        }
      }
    } catch (e) {
      debugPrint('Error consultando RAWG ($gameTitle): $e');
    }
    return null;
  }

  /// Enriquece un juego con metadatos faltantes y lo persiste en SQLite
  Future<Game> enrichGame(Game game, {String? rawgKey}) async {
    bool modified = false;
    String? newCover = game.coverUrl;
    List<String> newGenres = List.from(game.genres);
    num? newHltbMain = game.hltbMain;
    String? newLink = game.link;
    String newStatus = game.status;
    DateTime? newCompletedDate = game.completedDate;

    // 1. RAWG: si falta portada o géneros o HLTB
    if (rawgKey != null && rawgKey.trim().isNotEmpty) {
      final needsRawg = (newCover == null || newCover.isEmpty) ||
          newGenres.isEmpty ||
          (newHltbMain == null || newHltbMain == 0);

      if (needsRawg) {
        final rawgData = await searchRawg(game.title, rawgKey);
        if (rawgData != null) {
          if ((newCover == null || newCover.isEmpty) && rawgData['cover_url'] != null) {
            newCover = rawgData['cover_url'];
            modified = true;
          }
          if (newGenres.isEmpty && (rawgData['genres'] as List).isNotEmpty) {
            newGenres = List<String>.from(rawgData['genres']);
            modified = true;
          }
          if ((newHltbMain == null || newHltbMain == 0) &&
              rawgData['hltb_main'] != null &&
              rawgData['hltb_main'] > 0) {
            newHltbMain = rawgData['hltb_main'];
            modified = true;

            // Auto-culminación inmediata si las horas acumuladas ya superan HLTB
            final hours = game.hoursPlayed ?? 0;
            if (hours >= newHltbMain! && game.status != 'Jugado') {
              newStatus = 'Jugado';
              newCompletedDate ??= DateTime.now();
            }
          }
        }
      }
    }

    // 2. Wikipedia: si falta el enlace de referencia
    if (newLink == null || newLink.trim().isEmpty) {
      final wikiUrl = await searchWikipedia(game.title);
      if (wikiUrl != null && wikiUrl.isNotEmpty) {
        newLink = wikiUrl;
        modified = true;
      }
    }

    if (modified) {
      final enriched = game.copyWith(
        coverUrl: newCover,
        genres: newGenres,
        hltbMain: newHltbMain,
        link: newLink,
        status: newStatus,
        completedDate: newCompletedDate,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.instance.updateGame(enriched);
      return enriched;
    }

    return game;
  }
}
