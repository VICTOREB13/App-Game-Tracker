import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/game.dart';
import 'database_service.dart';
import 'hltb_service.dart';
import 'resilient_http_client.dart';
import 'string_normalizer.dart';

/// Servicio de enriquecimiento automático de metadatos (RAWG, Wikipedia y HLTB)
/// Replicación de `rellenar_metadata()` de `games.py`.
class MetadataService {
  static MetadataService? _instance;
  ResilientHttpClient _httpClient;

  MetadataService._({ResilientHttpClient? httpClient})
      : _httpClient = httpClient ?? ResilientHttpClient.instance;

  static MetadataService get instance {
    _instance ??= MetadataService._();
    return _instance!;
  }

  @visibleForTesting
  void setHttpClientForTesting(ResilientHttpClient client) {
    _httpClient = client;
  }

  /// Busca el enlace enciclopédico oficial en Wikipedia (probando español e inglés)
  Future<String?> searchWikipedia(String gameTitle) async {
    final cleanTitle = StringNormalizer.cleanSpecialCharacters(gameTitle);
    if (cleanTitle.isEmpty) return null;

    final searches = [
      {'lang': 'es', 'query': '$cleanTitle videojuego'},
      {'lang': 'en', 'query': '$cleanTitle video game'},
      {'lang': 'es', 'query': cleanTitle},
      {'lang': 'en', 'query': cleanTitle},
    ];

    for (final item in searches) {
      try {
        final lang = item['lang']!;
        final query = item['query']!;
        final url = Uri.https(
          '$lang.wikipedia.org',
          '/w/api.php',
          {
            'action': 'query',
            'list': 'search',
            'srsearch': query,
            'format': 'json',
            'srlimit': '1',
          },
        );

        final res = await _httpClient.get(
          url,
          headers: {
            'User-Agent':
                'GameTracker/3.0 (victorengineer.fyi; contact@victorengineer.fyi)'
          },
          timeout: const Duration(seconds: 5),
        );

        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final queryMap = data['query'] as Map<String, dynamic>?;
          final searchResults = queryMap?['search'] as List<dynamic>?;
          if (searchResults != null && searchResults.isNotEmpty) {
            final first = searchResults[0] as Map<String, dynamic>?;
            final title = first?['title']?.toString() ?? '';
            if (title.isNotEmpty) {
              final formattedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
              return 'https://$lang.wikipedia.org/wiki/$formattedTitle';
            }
          }
        }
      } catch (e) {
        debugPrint('Error consultando Wikipedia ($gameTitle): $e');
      }
    }
    return null;
  }

  /// Busca metadatos en RAWG API (portada HD y todos los géneros sin límites)
  Future<Map<String, dynamic>?> searchRawg(
      String gameTitle, String rawgKey) async {
    if (rawgKey.trim().isEmpty) return null;

    final cleanTitle = StringNormalizer.cleanSpecialCharacters(gameTitle);
    if (cleanTitle.isEmpty) return null;

    try {
      final url = Uri.https(
        'api.rawg.io',
        '/api/games',
        {
          'key': rawgKey.trim(),
          'search': cleanTitle,
          'page_size': '1',
        },
      );

      final res = await _httpClient.get(url, timeout: const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final match = results[0] as Map<String, dynamic>;
          final rawGenres = (match['genres'] as List<dynamic>?) ?? [];
          final genres = rawGenres
              .map((g) => (g as Map<String, dynamic>?)?['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          return {
            'cover_url': match['background_image']?.toString(),
            'genres': genres,
          };
        }
      }
    } catch (e) {
      debugPrint('Error consultando RAWG ($gameTitle): $e');
    }
    return null;
  }

  /// Busca juegos en RAWG API para autocompletado y catálogo paginado
  Future<List<Map<String, dynamic>>> searchRawgGames(
    String query,
    String rawgKey, {
    int pageSize = 15,
  }) async {
    final cleanQuery = StringNormalizer.cleanSpecialCharacters(query);
    if (cleanQuery.isEmpty || rawgKey.trim().isEmpty) return [];

    try {
      final url = Uri.https(
        'api.rawg.io',
        '/api/games',
        {
          'key': rawgKey.trim(),
          'search': cleanQuery,
          'page_size': pageSize.toString(),
        },
      );

      final res = await _httpClient.get(url, timeout: const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final rawResults = (data['results'] as List<dynamic>?) ?? [];
        return rawResults.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('Error en searchRawgGames RAWG ($query): $e');
    }
    return [];
  }

  /// Enriquece un juego con metadatos faltantes y lo persiste en SQLite
  Future<Game> enrichGame(Game game, {String? rawgKey}) async {
    bool modified = false;
    String? newCover = game.coverUrl;
    List<String> newGenres = List.from(game.genres);
    num? newHltbMain = game.hltbMain;
    num? newHltbComp = game.hltbCompletionist;
    String? newLink = game.link;
    String newStatus = game.status;
    DateTime? newCompletedDate = game.completedDate;

    // 1. HowLongToBeat: si falta la duración de campaña o completista
    final needsHltb = (newHltbMain == null || newHltbMain == 0) ||
        (newHltbComp == null || newHltbComp == 0);
    if (needsHltb) {
      try {
        final hltbData = await HltbService.instance.searchHltb(game.title);
        if (hltbData != null) {
          if (hltbData.mainStory != null &&
              (newHltbMain == null || newHltbMain == 0)) {
            newHltbMain = hltbData.mainStory;
            modified = true;
          }
          if (hltbData.completionist != null &&
              (newHltbComp == null || newHltbComp == 0)) {
            newHltbComp = hltbData.completionist;
            modified = true;
          }

          final progressed = game.copyWith(
            hltbMain: newHltbMain,
            status: newStatus,
            completedDate: newCompletedDate,
          ).applyPlaytimeProgress(totalHours: game.hoursPlayed ?? 0);
          if (progressed.status != newStatus) {
            newStatus = progressed.status;
            newCompletedDate = progressed.completedDate;
            modified = true;
          }
        }
      } catch (e) {
        debugPrint('Error enriqueciendo HLTB (${game.title}): $e');
      }
    }

    if (rawgKey != null && rawgKey.trim().isNotEmpty) {
      final needsRawg =
          (newCover == null || newCover.isEmpty) || newGenres.isEmpty;

      if (needsRawg) {
        final rawgData = await searchRawg(game.title, rawgKey);
        if (rawgData != null) {
          if ((newCover == null || newCover.isEmpty) &&
              rawgData['cover_url'] != null) {
            newCover = rawgData['cover_url']?.toString();
            modified = true;
          }
          if (newGenres.isEmpty && (rawgData['genres'] as List).isNotEmpty) {
            newGenres = (rawgData['genres'] as List<dynamic>)
                .map((e) => e.toString())
                .toList();
            modified = true;
          }
        }
      }
    }

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
        hltbCompletionist: newHltbComp,
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

  /// Sincroniza masivamente la duración de campaña y completista desde HowLongToBeat.
  /// Itera sobre los juegos dados (filtrando los pendientes por defecto si [onlyPending] es true),
  /// consultando [HltbService.searchHltb], aplicando [Game.applyPlaytimeProgress] y actualizando en SQLite.
  /// Retorna un mapa con contadores: `{ 'total': ..., 'updated': ..., 'failed': ..., 'auto_culminated': ... }`.
  Future<Map<String, int>> syncAllHltbGames({
    required List<Game> games,
    bool onlyPending = true,
    void Function(int current, int total, String title)? onProgress,
  }) async {
    final targets = onlyPending
        ? games
            .where((g) =>
                (g.hltbMain == null || g.hltbMain == 0) ||
                (g.hltbCompletionist == null || g.hltbCompletionist == 0))
            .toList()
        : games;

    if (targets.isEmpty) {
      return {
        'total': 0,
        'updated': 0,
        'failed': 0,
        'auto_culminated': 0,
      };
    }

    int updated = 0;
    int failed = 0;
    int autoCulminated = 0;

    for (int i = 0; i < targets.length; i++) {
      final game = targets[i];
      onProgress?.call(i + 1, targets.length, game.title);

      try {
        final result = await HltbService.instance.searchHltb(game.title);
        if (result != null &&
            (result.mainStory != null || result.completionist != null)) {
          final newMain = result.mainStory ?? game.hltbMain;
          final newComp = result.completionist ?? game.hltbCompletionist;

          final progressed = game.copyWith(
            hltbMain: newMain,
            hltbCompletionist: newComp,
            updatedAt: DateTime.now(),
          ).applyPlaytimeProgress(totalHours: game.hoursPlayed ?? 0);

          if (progressed.status != game.status &&
              progressed.status == 'Jugado') {
            autoCulminated++;
          }

          await DatabaseService.instance.updateGame(progressed);
          updated++;
        }
      } catch (e) {
        failed++;
        debugPrint('Error enriqueciendo HLTB (${game.title}): $e');
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return {
      'total': targets.length,
      'updated': updated,
      'failed': failed,
      'auto_culminated': autoCulminated,
    };
  }

  /// Sincroniza masivamente metadatos (RAWG y Wikipedia) para los juegos indicados.
  /// Itera sobre los juegos enriqueciendo con RAWG y Wikipedia mediante [enrichGame]
  /// y persiste en la base de datos SQLite.
  /// Retorna un mapa con contadores: `{ 'total': ..., 'updated': ..., 'failed': ..., 'genres_updated': ..., 'wiki_updated': ..., 'covers_updated': ... }`.
  Future<Map<String, int>> syncAllGamesMetadata({
    required List<Game> games,
    required String rawgKey,
    bool onlyPending = true,
    void Function(int current, int total, String title)? onProgress,
  }) async {
    final targets = onlyPending
        ? games
            .where((g) =>
                g.genres.isEmpty ||
                (g.link == null || g.link!.trim().isEmpty) ||
                (g.coverUrl == null || g.coverUrl!.trim().isEmpty))
            .toList()
        : games;

    if (targets.isEmpty) {
      return {
        'total': 0,
        'updated': 0,
        'failed': 0,
        'genres_updated': 0,
        'wiki_updated': 0,
        'covers_updated': 0,
      };
    }

    int updated = 0;
    int failed = 0;
    int genresUpdated = 0;
    int wikiUpdated = 0;
    int coversUpdated = 0;

    for (int i = 0; i < targets.length; i++) {
      final game = targets[i];
      onProgress?.call(i + 1, targets.length, game.title);

      final hadGenres = game.genres.isNotEmpty;
      final hadCover =
          game.coverUrl != null && game.coverUrl!.trim().isNotEmpty;
      final hadLink = game.link != null && game.link!.trim().isNotEmpty;

      try {
        final enriched = await enrichGame(game, rawgKey: rawgKey);
        if (!identical(enriched, game)) {
          updated++;
          if (!hadGenres && enriched.genres.isNotEmpty) {
            genresUpdated++;
          }
          if (!hadCover &&
              (enriched.coverUrl != null &&
                  enriched.coverUrl!.trim().isNotEmpty)) {
            coversUpdated++;
          }
          if (!hadLink &&
              (enriched.link != null && enriched.link!.trim().isNotEmpty)) {
            wikiUpdated++;
          }
        }
      } catch (e) {
        failed++;
        debugPrint('Error enriqueciendo metadatos (${game.title}): $e');
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return {
      'total': targets.length,
      'updated': updated,
      'failed': failed,
      'genres_updated': genresUpdated,
      'wiki_updated': wikiUpdated,
      'covers_updated': coversUpdated,
    };
  }
}
