import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/game.dart';
import 'database_service.dart';
import 'hltb_service.dart';
import 'metadata_service.dart';
import 'resilient_http_client.dart';
import 'secure_storage_service.dart';
import 'string_normalizer.dart';

/// Fases del proceso de sincronización con Steam
enum SyncPhase {
  fetching,
  savingCore,
  enriching,
  completed,
}

/// Estado de progreso tipado para seguimiento en tiempo real
class SyncProgress {
  final SyncPhase phase;
  final int total;
  final int current;
  final String? currentGameTitle;
  final String message;

  const SyncProgress({
    required this.phase,
    this.total = 0,
    this.current = 0,
    this.currentGameTitle,
    required this.message,
  });

  double get progressPercentage =>
      total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

  @override
  String toString() => 'SyncProgress($phase: $current/$total - $message)';
}

/// Resumen estructurado del resultado de la sincronización con Steam
class SteamSyncResult {
  final int totalFound;
  final int processedCount;
  final int updatedCount;
  final int createdCount;
  final int familySharingCount;
  final int autoCulminatedCount;
  final List<String> details;

  SteamSyncResult({
    required this.totalFound,
    required this.processedCount,
    required this.updatedCount,
    required this.createdCount,
    required this.familySharingCount,
    required this.autoCulminatedCount,
    required this.details,
  });

  @override
  String toString() {
    return 'SteamSyncResult(totalFound: $totalFound, actualizados: $updatedCount, creados: $createdCount, familySharing: $familySharingCount, autoCulminados: $autoCulminatedCount)';
  }
}

/// Servicio nativo de integración con Steam Web API.
/// Implementa arquitectura desacoplada en dos fases:
/// - Fase 1: Importación rápida y persistencia en lote (< 1 seg).
/// - Fase 2: Cola en segundo plano para enriquecimiento (HLTB, RAWG, Wikipedia) con pool de concurrencia controlado.
class SteamService {
  static SteamService? _instance;
  ResilientHttpClient _httpClient;

  SteamService._({ResilientHttpClient? httpClient})
      : _httpClient = httpClient ?? ResilientHttpClient.instance;

  static SteamService get instance {
    _instance ??= SteamService._();
    return _instance!;
  }

  @visibleForTesting
  void setHttpClientForTesting(ResilientHttpClient client) {
    _httpClient = client;
  }

  /// Valida si la API Key y SteamID son legítimos consultando el perfil del jugador
  Future<bool> validateCredentials(String apiKey, String steamId) async {
    try {
      final cleanKey = apiKey.trim();
      final cleanId = steamId.trim();
      if (cleanKey.isEmpty || cleanId.isEmpty) return false;

      final url = Uri.https(
        'api.steampowered.com',
        '/ISteamUser/GetPlayerSummaries/v0002/',
        {
          'key': cleanKey,
          'steamids': cleanId,
        },
      );

      final res = await _httpClient.get(url, timeout: const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final responseMap = data['response'] as Map<String, dynamic>?;
        final players = responseMap?['players'] as List<dynamic>?;
        return players != null && players.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Resuelve un nombre de usuario personalizado (Vanity URL) a su SteamID64 numérico
  Future<String?> resolveVanityUrl(String apiKey, String vanityUrl) async {
    try {
      final cleanVanity = vanityUrl
          .trim()
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .replaceAll('steamcommunity.com/id/', '')
          .replaceAll('/', '');

      // Si ya es un ID numérico de 17 dígitos, retornarlo directamente
      if (RegExp(r'^\d{17}$').hasMatch(cleanVanity)) {
        return cleanVanity;
      }

      final url = Uri.https(
        'api.steampowered.com',
        '/ISteamUser/ResolveVanityURL/v0001/',
        {
          'key': apiKey.trim(),
          'vanityurl': cleanVanity,
        },
      );

      final res = await _httpClient.get(url, timeout: const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final responseMap = data['response'] as Map<String, dynamic>?;
        if (responseMap?['success'] == 1) {
          return responseMap?['steamid']?.toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los juegos de Steam combinando dos fuentes:
  /// 1. GetOwnedGames: juegos comprados por el usuario
  /// 2. GetRecentlyPlayedGames: juegos recientes (incluye Family Sharing)
  Future<Map<int, Map<String, dynamic>>> fetchSteamGames({
    required String apiKey,
    required String steamId,
  }) async {
    final Map<int, Map<String, dynamic>> games = {};
    final cleanKey = apiKey.trim();
    final cleanId = steamId.trim();

    // 1. Consulta de Juegos Propios (GetOwnedGames)
    try {
      final ownedUrl = Uri.https(
        'api.steampowered.com',
        '/IPlayerService/GetOwnedGames/v0001/',
        {
          'key': cleanKey,
          'steamid': cleanId,
          'format': 'json',
          'include_appinfo': 'true',
          'include_played_free_games': 'true',
        },
      );
      final r = await _httpClient.get(ownedUrl, timeout: const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final responseMap = data['response'] as Map<String, dynamic>?;
        final list = (responseMap?['games'] as List<dynamic>?) ?? [];
        for (final dynamic g in list) {
          final gMap = g as Map<String, dynamic>;
          final aid = gMap['appid'] as int?;
          if (aid != null) {
            games[aid] = Map<String, dynamic>.from(gMap);
          }
        }
      }
    } catch (e) {
      debugPrint('Error en GetOwnedGames de Steam: $e');
    }

    // 2. Consulta de Juegos Recientes / Family Sharing (GetRecentlyPlayedGames)
    try {
      final recentUrl = Uri.https(
        'api.steampowered.com',
        '/IPlayerService/GetRecentlyPlayedGames/v0001/',
        {
          'key': cleanKey,
          'steamid': cleanId,
          'format': 'json',
        },
      );
      final r = await _httpClient.get(recentUrl, timeout: const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final responseMap = data['response'] as Map<String, dynamic>?;
        final recentList = (responseMap?['games'] as List<dynamic>?) ?? [];

        for (final dynamic g in recentList) {
          final gMap = g as Map<String, dynamic>;
          final aid = gMap['appid'] as int?;
          if (aid == null) continue;

          if (!games.containsKey(aid)) {
            // Este juego NO está en propios -> es Family Sharing
            final newGMap = Map<String, dynamic>.from(gMap);
            newGMap['is_family_sharing'] = true;
            games[aid] = newGMap;
          } else {
            // Si el tiempo reciente es mayor, refrescarlo
            final existingMinutes = (games[aid]!['playtime_forever'] as num?)?.toInt() ?? 0;
            final recentMinutes = (gMap['playtime_forever'] as num?)?.toInt() ?? 0;
            if (recentMinutes > existingMinutes) {
              games[aid]!['playtime_forever'] = recentMinutes;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error en GetRecentlyPlayedGames de Steam: $e');
    }

    return games;
  }

  /// Sincroniza la biblioteca de Steam con la base de datos local SQLite.
  /// Desacoplado en dos fases:
  /// - Fase 1: Importación rápida y persistencia en lote con `batchUpsertGames` (< 1 seg).
  /// - Fase 2: Cola en segundo plano para enriquecimiento (HLTB, RAWG, Wikipedia) con pool de concurrencia controlado (2 workers y delay de 300 ms).
  Future<SteamSyncResult> syncWithDatabase({
    required String apiKey,
    required String steamId,
    bool importUnder30Min = false,
    void Function(SyncProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(const SyncProgress(
      phase: SyncPhase.fetching,
      total: 0,
      current: 0,
      message: 'Consultando biblioteca de Steam...',
    ));

    final steamGames = await fetchSteamGames(apiKey: apiKey, steamId: steamId);
    final db = DatabaseService.instance;
    final allDbGames = await db.getAllGames();

    // Índices auxiliares en memoria para matching inmediato
    final Map<int, Game> gamesBySteamId = {};
    final Map<String, Game> gamesByCleanTitle = {};

    for (final g in allDbGames) {
      if (g.steamId != null) {
        gamesBySteamId[g.steamId!.toInt()] = g;
      }
      final clean = StringNormalizer.cleanTitle(g.title);
      if (clean.isNotEmpty) {
        gamesByCleanTitle[clean] = g;
      }
    }

    int updatedCount = 0;
    int createdCount = 0;
    int familySharingCount = 0;
    int autoCulminatedCount = 0;
    int processedCount = 0;
    final List<String> details = [];

    // Constante de estados finales que no se auto-degradan
    const estadosFinales = ['Jugado'];

    final rawgKey = await SecureStorageService.instance.getRawgKey() ?? '';

    // Lista de juegos a persistir en lote en Fase 1
    final List<Game> coreGamesToUpsert = [];
    // Lista de juegos que requerirán enriquecimiento en Fase 2
    final List<Game> gamesToEnrich = [];

    // ==========================================
    // FASE 1: Importación Core y Lote Atómico
    // ==========================================
    for (final entry in steamGames.entries) {
      if (isCancelled != null && isCancelled()) break;

      final appid = entry.key;
      final g = entry.value;
      final name = g['name']?.toString() ?? 'Steam App $appid';
      final minutes = (g['playtime_forever'] as num?)?.toDouble() ?? 0.0;
      final hours = minutes / 60.0;

      if (g['is_family_sharing'] == true) {
        familySharingCount++;
      }

      // FILTRO: Solo procesamos juegos con más de 30 minutos (0.5 horas)
      if (!importUnder30Min && hours < 0.5) {
        continue;
      }

      processedCount++;
      final cleanSteamName = StringNormalizer.cleanTitle(name);

      // --- ESTRATEGIA TRI-FASE DE BÚSQUEDA ---
      Game? matchedGame;

      // Intento 1: Coincidencia exacta por Steam ID indexado
      if (gamesBySteamId.containsKey(appid)) {
        matchedGame = gamesBySteamId[appid];
      }
      // Intento 2: Coincidencia exacta por nombre normalizado
      else if (gamesByCleanTitle.containsKey(cleanSteamName)) {
        matchedGame = gamesByCleanTitle[cleanSteamName];
      }
      // Intento 3: Similitud difusa (Fuzzy Matching > 0.90)
      else {
        for (final item in gamesByCleanTitle.entries) {
          if (StringNormalizer.similarity(cleanSteamName, item.key) >= 0.90) {
            matchedGame = item.value;
            break;
          }
        }
      }

      final roundedNewHours = double.parse(hours.toStringAsFixed(1));

      if (matchedGame != null) {
        // --- JUEGO EXISTENTE: ACTUALIZAR DATOS CORE ---
        bool needsUpdate = false;
        final currentHours = matchedGame.hoursPlayed?.toDouble() ?? 0.0;
        final roundedCurrentHours = double.parse(currentHours.toStringAsFixed(1));

        num finalHours = matchedGame.hoursPlayed ?? 0;
        DateTime? finalStartDate = matchedGame.startDate;
        DateTime? finalCompletedDate = matchedGame.completedDate;
        String finalStatus = matchedGame.status;
        num? finalSteamId = matchedGame.steamId ?? appid;

        // 1. Horas jugadas
        if (roundedNewHours != roundedCurrentHours) {
          finalHours = roundedNewHours;
          needsUpdate = true;
        }

        // 2. Steam ID si faltaba
        if (matchedGame.steamId == null || matchedGame.steamId != appid) {
          finalSteamId = appid;
          needsUpdate = true;
        }

        // 3. Fecha de inicio: si tiene horas pero no tenía fecha
        if (hours > 0 && finalStartDate == null) {
          finalStartDate = DateTime.now();
          needsUpdate = true;
        }

        // 4. Auto-Culminación inmediata si ya tenía HLTB cargado
        final hltbMain = matchedGame.hltbMain?.toDouble();
        if (hltbMain != null &&
            hltbMain > 0 &&
            roundedNewHours >= hltbMain &&
            !estadosFinales.contains(matchedGame.status)) {
          finalStatus = 'Jugado';
          finalCompletedDate ??= DateTime.now();
          autoCulminatedCount++;
          needsUpdate = true;
          details.add('🏆 Auto-culminado por HLTB: $name ($roundedNewHours h >= $hltbMain h)');
        } else if (matchedGame.status == 'Por jugar' && roundedNewHours >= 1.0) {
          finalStatus = 'Jugando';
          finalStartDate ??= DateTime.now();
          needsUpdate = true;
        }

        final updatedGame = matchedGame.copyWith(
          hoursPlayed: finalHours,
          steamId: finalSteamId,
          startDate: finalStartDate,
          completedDate: finalCompletedDate,
          status: finalStatus,
          updatedAt: DateTime.now(),
        );

        if (needsUpdate) {
          coreGamesToUpsert.add(updatedGame);
          updatedCount++;
          gamesBySteamId[appid] = updatedGame;
          gamesByCleanTitle[cleanSteamName] = updatedGame;
        }

        // Evaluar si requiere enriquecimiento en Fase 2
        final needsEnrichment = (updatedGame.hltbMain == null || updatedGame.hltbMain == 0) ||
            (updatedGame.link == null || updatedGame.link!.isEmpty) ||
            (updatedGame.genres.isEmpty && rawgKey.isNotEmpty);

        if (needsEnrichment) {
          gamesToEnrich.add(updatedGame);
        }
      } else {
        // --- JUEGO NUEVO: CREAR CON METADATOS BÁSICOS ---
        final steamCoverUrl =
            'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appid/header.jpg';

        final status = roundedNewHours >= 1.0 ? 'Jugando' : 'Por jugar';
        final startDate = roundedNewHours >= 1.0 ? DateTime.now() : null;

        final newGame = Game(
          title: name,
          coverUrl: steamCoverUrl,
          status: status,
          platform: 'PC',
          hoursPlayed: roundedNewHours,
          steamId: appid,
          startDate: startDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        coreGamesToUpsert.add(newGame);
        createdCount++;
        details.add('✨ Creado desde Steam: $name ($roundedNewHours h)');

        gamesBySteamId[appid] = newGame;
        gamesByCleanTitle[cleanSteamName] = newGame;
        gamesToEnrich.add(newGame);
      }
    }

    // Persistencia atómica ultrarrápida de Fase 1
    if (coreGamesToUpsert.isNotEmpty) {
      onProgress?.call(SyncProgress(
        phase: SyncPhase.savingCore,
        total: coreGamesToUpsert.length,
        current: coreGamesToUpsert.length,
        message: 'Guardando ${coreGamesToUpsert.length} juegos en SQLite...',
      ));
      await db.batchUpsertGames(coreGamesToUpsert);
    }

    // ==========================================
    // FASE 2: Cola de Enriquecimiento en Segundo Plano
    // Pool de 2 Workers con Delay de 300 ms
    // ==========================================
    final totalToEnrich = gamesToEnrich.length;
    int enrichedProcessed = 0;

    if (totalToEnrich > 0) {
      onProgress?.call(SyncProgress(
        phase: SyncPhase.enriching,
        total: totalToEnrich,
        current: 0,
        message: 'Iniciando enriquecimiento de metadatos (HLTB, RAWG, Wikipedia)...',
      ));

      Future<void> enrichWorker(List<Game> chunk) async {
        for (final game in chunk) {
          if (isCancelled != null && isCancelled()) break;

          try {
            final enriched = await _enrichSingleGame(
              game,
              rawgKey,
              details,
              (culminated) {
                if (culminated) autoCulminatedCount++;
              },
            );

            if (enriched != null) {
              await db.updateGame(enriched);
            }
          } catch (e) {
            debugPrint('Error enriqueciendo ${game.title}: $e');
          }

          enrichedProcessed++;
          onProgress?.call(SyncProgress(
            phase: SyncPhase.enriching,
            total: totalToEnrich,
            current: enrichedProcessed,
            currentGameTitle: game.title,
            message: 'Enriqueciendo: ${game.title} ($enrichedProcessed/$totalToEnrich)',
          ));

          // Delay de 300 ms entre llamadas para proteger rate limits
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }

      final mid = (totalToEnrich / 2).ceil();
      final chunk1 = gamesToEnrich.sublist(0, mid);
      final chunk2 = gamesToEnrich.sublist(mid);

      await Future.wait([
        enrichWorker(chunk1),
        if (chunk2.isNotEmpty) enrichWorker(chunk2),
      ]);
    }

    onProgress?.call(SyncProgress(
      phase: SyncPhase.completed,
      total: processedCount,
      current: processedCount,
      message: 'Sincronización con Steam completada.',
    ));

    return SteamSyncResult(
      totalFound: steamGames.length,
      processedCount: processedCount,
      updatedCount: updatedCount,
      createdCount: createdCount,
      familySharingCount: familySharingCount,
      autoCulminatedCount: autoCulminatedCount,
      details: details,
    );
  }

  /// Enriquece un solo juego con HLTB, RAWG y Wikipedia
  Future<Game?> _enrichSingleGame(
    Game game,
    String rawgKey,
    List<String> details,
    void Function(bool autoCulminated) onAutoCulminate,
  ) async {
    bool modified = false;
    num? hltbMain = game.hltbMain;
    num? hltbComp = game.hltbCompletionist;
    String? link = game.link;
    String? coverUrl = game.coverUrl;
    List<String> genres = List.from(game.genres);
    String status = game.status;
    DateTime? completedDate = game.completedDate;

    // 1. HLTB
    if (hltbMain == null || hltbMain == 0) {
      try {
        final hltbData = await HltbService.instance.searchHltb(game.title);
        if (hltbData != null) {
          if (hltbData.mainStory != null) {
            hltbMain = hltbData.mainStory;
            modified = true;
          }
          if (hltbData.completionist != null) {
            hltbComp = hltbData.completionist;
            modified = true;
          }

          // Auto-culminación si las horas superan HLTB
          final hours = game.hoursPlayed?.toDouble() ?? 0.0;
          if (hltbMain != null &&
              hltbMain > 0 &&
              hours >= hltbMain &&
              status != 'Jugado') {
            status = 'Jugado';
            completedDate ??= DateTime.now();
            modified = true;
            onAutoCulminate(true);
            details.add('🏆 Auto-culminado por HLTB: ${game.title} ($hours h >= $hltbMain h)');
          }
        }
      } catch (e) {
        debugPrint('Error HLTB en enriquecimiento de ${game.title}: $e');
      }
    }

    // 2. Wikipedia
    if (link == null || link.trim().isEmpty) {
      try {
        final wikiUrl = await MetadataService.instance.searchWikipedia(game.title);
        if (wikiUrl != null && wikiUrl.isNotEmpty) {
          link = wikiUrl;
          modified = true;
        }
      } catch (e) {
        debugPrint('Error Wikipedia en enriquecimiento de ${game.title}: $e');
      }
    }

    // 3. RAWG
    if (rawgKey.isNotEmpty && (genres.isEmpty || coverUrl == null || coverUrl.contains('fastly.steamstatic.com'))) {
      try {
        final rawgData = await MetadataService.instance.searchRawg(game.title, rawgKey);
        if (rawgData != null) {
          if (rawgData['cover_url'] != null && rawgData['cover_url'].toString().isNotEmpty) {
            coverUrl = rawgData['cover_url']?.toString();
            modified = true;
          }
          if (genres.isEmpty && rawgData['genres'] != null && (rawgData['genres'] as List<dynamic>).isNotEmpty) {
            genres = (rawgData['genres'] as List<dynamic>).map((e) => e.toString()).toList();
            modified = true;
          }
        }
      } catch (e) {
        debugPrint('Error RAWG en enriquecimiento de ${game.title}: $e');
      }
    }

    if (modified) {
      return game.copyWith(
        hltbMain: hltbMain,
        hltbCompletionist: hltbComp,
        link: link,
        coverUrl: coverUrl,
        genres: genres,
        status: status,
        completedDate: completedDate,
        updatedAt: DateTime.now(),
      );
    }

    return null;
  }
}
