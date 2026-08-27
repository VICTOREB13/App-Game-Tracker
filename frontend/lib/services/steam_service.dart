import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import 'database_service.dart';
import 'string_normalizer.dart';
import 'hltb_service.dart';
import 'metadata_service.dart';

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
/// Replicación integral al 100% de la lógica de sincronización de `games.py`.
class SteamService {
  static SteamService? _instance;

  SteamService._();

  static SteamService get instance {
    _instance ??= SteamService._();
    return _instance!;
  }

  /// Valida si la API Key y SteamID son legítimos consultando el perfil del jugador
  Future<bool> validateCredentials(String apiKey, String steamId) async {
    try {
      final cleanKey = apiKey.trim();
      final cleanId = steamId.trim();
      if (cleanKey.isEmpty || cleanId.isEmpty) return false;

      final url = Uri.parse(
          'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$cleanKey&steamids=$cleanId');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final players = data['response']?['players'] as List?;
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

      final url = Uri.parse(
          'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=${apiKey.trim()}&vanityurl=$cleanVanity');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['response']?['success'] == 1) {
          return data['response']?['steamid']?.toString();
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
      final ownedUrl = Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/'
        '?key=$cleanKey&steamid=$cleanId&format=json'
        '&include_appinfo=true&include_played_free_games=true',
      );
      final r = await http.get(ownedUrl).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final list = data['response']?['games'] as List? ?? [];
        for (final g in list) {
          final aid = g['appid'] as int?;
          if (aid != null) {
            games[aid] = Map<String, dynamic>.from(g);
          }
        }
      }
    } catch (e) {
      debugPrint('Error en GetOwnedGames de Steam: $e');
    }

    // 2. Consulta de Juegos Recientes / Family Sharing (GetRecentlyPlayedGames)
    try {
      final recentUrl = Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/'
        '?key=$cleanKey&steamid=$cleanId&format=json',
      );
      final r = await http.get(recentUrl).timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final recentList = data['response']?['games'] as List? ?? [];

        for (final g in recentList) {
          final aid = g['appid'] as int?;
          if (aid == null) continue;

          if (!games.containsKey(aid)) {
            // Este juego NO está en propios -> es Family Sharing
            final gMap = Map<String, dynamic>.from(g);
            gMap['is_family_sharing'] = true;
            games[aid] = gMap;
          } else {
            // Si el tiempo reciente es mayor, refrescarlo
            final existingMinutes = games[aid]!['playtime_forever'] ?? 0;
            final recentMinutes = g['playtime_forever'] ?? 0;
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
  /// Implementa exactamente las reglas de negocio de `games.py`:
  /// - Filtro < 0.5 horas (omite juegos con menos de 30 minutos).
  /// - Estrategia tri-fase de matching (Steam ID -> Nombre limpio -> Fuzzy > 0.9).
  /// - Creación: horas > 1 ? 'Jugado' : 'Por Jugar', fecha_inicio = hoy.
  /// - Actualización: horas, fecha inicio y Auto-Culminación por HLTB.
  Future<SteamSyncResult> syncWithDatabase({
    required String apiKey,
    required String steamId,
    bool importUnder30Min = false,
  }) async {
    final steamGames = await fetchSteamGames(apiKey: apiKey, steamId: steamId);
    final db = DatabaseService.instance;
    final allDbGames = await db.getAllGames();

    // Índices auxiliares en memoria para búsqueda inmediata
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

    final prefs = await SharedPreferences.getInstance();
    final rawgKey = prefs.getString('rawg_api_key') ?? '';

    for (final entry in steamGames.entries) {
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
        // --- JUEGO EXISTENTE: ACTUALIZAR SOLO SI CAMBIÓ ---
        bool needsUpdate = false;
        final currentHours = matchedGame.hoursPlayed?.toDouble() ?? 0.0;
        final roundedCurrentHours = double.parse(currentHours.toStringAsFixed(1));

        num finalHours = matchedGame.hoursPlayed ?? 0;
        DateTime? finalStartDate = matchedGame.startDate;
        DateTime? finalCompletedDate = matchedGame.completedDate;
        String finalStatus = matchedGame.status;
        num? finalSteamId = matchedGame.steamId ?? appid;
        num? finalHltbMain = matchedGame.hltbMain;
        num? finalHltbComp = matchedGame.hltbCompletionist;

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

        // 4. HLTB: si faltan los metadatos de duración, consultarlos en HowLongToBeat
        if (finalHltbMain == null || finalHltbMain == 0) {
          try {
            final hltbData = await HltbService.instance.searchHltb(matchedGame.title);
            if (hltbData != null) {
              if (hltbData.mainStory != null) {
                finalHltbMain = hltbData.mainStory;
                needsUpdate = true;
              }
              if (hltbData.completionist != null) {
                finalHltbComp = hltbData.completionist;
                needsUpdate = true;
              }
            }
          } catch (e) {
            debugPrint('Error buscando HLTB para ${matchedGame.title}: $e');
          }
        }

        // 5. Auto-Culminación por HLTB
        final hltbMain = finalHltbMain?.toDouble();
        if (hltbMain != null &&
            hltbMain > 0 &&
            roundedNewHours >= hltbMain &&
            !estadosFinales.contains(matchedGame.status)) {
          finalStatus = 'Jugado';
          finalCompletedDate ??= DateTime.now();
          autoCulminatedCount++;
          needsUpdate = true;
          details.add('🏆 Auto-culminado por HLTB: $name ($roundedNewHours h >= $hltbMain h)');
        }

        // 6. Wikipedia: si no tiene link, buscarlo
        String? finalLink = matchedGame.link;
        if (finalLink == null || finalLink.trim().isEmpty) {
          try {
            final wikiUrl = await MetadataService.instance.searchWikipedia(matchedGame.title);
            if (wikiUrl != null && wikiUrl.isNotEmpty) {
              finalLink = wikiUrl;
              needsUpdate = true;
            }
          } catch (_) {}
        }

        // 7. Géneros RAWG: si no tiene géneros y hay clave de RAWG
        List<String> finalGenres = List.from(matchedGame.genres);
        if (finalGenres.isEmpty && rawgKey.isNotEmpty) {
          try {
            final rawgData = await MetadataService.instance.searchRawg(matchedGame.title, rawgKey);
            if (rawgData != null && rawgData['genres'] != null && (rawgData['genres'] as List).isNotEmpty) {
              finalGenres = List<String>.from(rawgData['genres']);
              needsUpdate = true;
            }
          } catch (_) {}
        }

        if (needsUpdate) {
          final updated = matchedGame.copyWith(
            hoursPlayed: finalHours,
            steamId: finalSteamId,
            startDate: finalStartDate,
            completedDate: finalCompletedDate,
            status: finalStatus,
            hltbMain: finalHltbMain,
            hltbCompletionist: finalHltbComp,
            link: finalLink,
            genres: finalGenres,
            updatedAt: DateTime.now(),
          );
          await db.updateGame(updated);
          updatedCount++;
          // Refrescar referencias en memoria
          gamesBySteamId[appid] = updated;
          gamesByCleanTitle[cleanSteamName] = updated;
        }
      } else {
        // --- JUEGO NUEVO: CREAR EN SQLITE ---
        // Portada oficial de Steam CDN como fallback
        final steamCoverUrl =
            'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appid/header.jpg';

        // Consultar HowLongToBeat para el nuevo juego
        num? newHltbMain;
        num? newHltbComp;
        try {
          final hltbData = await HltbService.instance.searchHltb(name);
          if (hltbData != null) {
            newHltbMain = hltbData.mainStory;
            newHltbComp = hltbData.completionist;
          }
        } catch (e) {
          debugPrint('Error buscando HLTB para juego nuevo $name: $e');
        }

        // Consultar Wikipedia para enlace oficial
        String? newLink;
        try {
          newLink = await MetadataService.instance.searchWikipedia(name);
        } catch (e) {
          debugPrint('Error buscando Wikipedia para juego nuevo $name: $e');
        }

        // Consultar RAWG para géneros y portada HD (si hay clave de RAWG configurada)
        List<String> newGenres = [];
        String finalCover = steamCoverUrl;
        if (rawgKey.isNotEmpty) {
          try {
            final rawgData = await MetadataService.instance.searchRawg(name, rawgKey);
            if (rawgData != null) {
              if (rawgData['cover_url'] != null && (rawgData['cover_url'] as String).isNotEmpty) {
                finalCover = rawgData['cover_url'];
              }
              if (rawgData['genres'] != null && (rawgData['genres'] as List).isNotEmpty) {
                newGenres = List<String>.from(rawgData['genres']);
              }
            }
          } catch (e) {
            debugPrint('Error buscando RAWG para juego nuevo $name: $e');
          }
        }

        // Regla: si horas > 1h -> "Jugado", sino "Por Jugar"
        String status = roundedNewHours > 1.0 ? 'Jugado' : 'Por jugar';
        DateTime? completedDate;

        // Auto-culminar si horas >= HLTB historia principal
        if (newHltbMain != null &&
            newHltbMain > 0 &&
            roundedNewHours >= newHltbMain) {
          status = 'Jugado';
          completedDate = DateTime.now();
          autoCulminatedCount++;
          details.add('🏆 Auto-culminado por HLTB: $name ($roundedNewHours h >= $newHltbMain h)');
        }

        final startDate = roundedNewHours > 0 ? DateTime.now() : null;

        final newGame = Game(
          title: name,
          coverUrl: finalCover,
          status: status,
          platform: 'PC',
          hoursPlayed: roundedNewHours,
          steamId: appid,
          genres: newGenres,
          hltbMain: newHltbMain,
          hltbCompletionist: newHltbComp,
          link: newLink,
          startDate: startDate,
          completedDate: completedDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.insertGame(newGame);
        createdCount++;
        details.add('✨ Creado desde Steam: $name ($roundedNewHours h)');

        // Añadir a índices en memoria
        gamesBySteamId[appid] = newGame;
        gamesByCleanTitle[cleanSteamName] = newGame;
      }
    }

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
}
