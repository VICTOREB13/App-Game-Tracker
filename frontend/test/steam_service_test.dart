import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tracker_app/services/database_service.dart';
import 'package:tracker_app/services/hltb_service.dart';
import 'package:tracker_app/services/metadata_service.dart';
import 'package:tracker_app/services/resilient_http_client.dart';
import 'package:tracker_app/services/steam_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE games (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              cover_url TEXT,
              status TEXT NOT NULL DEFAULT 'Por jugar',
              platform TEXT,
              hours_played REAL DEFAULT 0.0,
              genres TEXT,
              rating TEXT,
              hltb_main REAL,
              hltb_completionist REAL,
              summary TEXT,
              link TEXT,
              start_date TEXT,
              completed_date TEXT,
              steam_id INTEGER,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('SteamService Unit Tests with Mock HTTP Client', () {
    test('validateCredentials valida perfil de Steam correctamente', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('GetPlayerSummaries')) {
          return http.Response(
            json.encode({
              'response': {
                'players': <Map<String, dynamic>>[
                  {'personaname': 'GamerVic', 'steamid': '76561198000000000'}
                ]
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      SteamService.instance.setHttpClientForTesting(resilient);

      final isValid = await SteamService.instance.validateCredentials('valid_key', '76561198000000000');
      expect(isValid, isTrue);

      final isInvalid = await SteamService.instance.validateCredentials('', '');
      expect(isInvalid, isFalse);
    });

    test('resolveVanityUrl resuelve nombres de usuario a SteamID64', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('ResolveVanityURL')) {
          return http.Response(
            json.encode({
              'response': {'steamid': '76561198123456789', 'success': 1}
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      SteamService.instance.setHttpClientForTesting(resilient);

      final steamId = await SteamService.instance.resolveVanityUrl('test_key', 'victor');
      expect(steamId, equals('76561198123456789'));

      // Direct ID
      final directId = await SteamService.instance.resolveVanityUrl('test_key', '76561198999999999');
      expect(directId, equals('76561198999999999'));
    });

    test('syncWithDatabase ejecuta Fase 1 (Core Batch) y Fase 2 (Enriquecimiento)', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('GetOwnedGames')) {
          return http.Response(
            json.encode({
              'response': {
                'game_count': 2,
                'games': <Map<String, dynamic>>[
                  {
                    'appid': 1086940,
                    'name': "Baldur's Gate 3",
                    'playtime_forever': 3600, // 60 horas
                  },
                  {
                    'appid': 1145360,
                    'name': 'Hades',
                    'playtime_forever': 1800, // 30 horas
                  },
                ]
              }
            }),
            200,
          );
        }

        if (path.contains('GetRecentlyPlayedGames')) {
          return http.Response(
            json.encode({
              'response': {'total_count': 0, 'games': <Map<String, dynamic>>[]}
            }),
            200,
          );
        }

        // HLTB Mock
        if (request.url.host.contains('howlongtobeat')) {
          if (path.contains('init')) {
            return http.Response(json.encode({'token': 'test_token', 'hpKey': 'k', 'hpVal': 'v'}), 200);
          }
          return http.Response(
            json.encode({
              'data': <Map<String, dynamic>>[
                {
                  'game_id': 1,
                  'game_name': "Baldur's Gate 3",
                  'comp_main': 3600 * 50, // 50h
                  'comp_plus': 3600 * 90,
                  'comp_100': 3600 * 150,
                }
              ]
            }),
            200,
          );
        }

        // Wikipedia Mock
        if (request.url.host.contains('wikipedia')) {
          return http.Response(
            json.encode({
              'query': {
                'search': <Map<String, dynamic>>[
                  {'title': 'Baldur\'s Gate 3'}
                ]
              }
            }),
            200,
          );
        }

        // RAWG Mock
        if (request.url.host.contains('rawg')) {
          return http.Response(
            json.encode({
              'results': <Map<String, dynamic>>[
                {
                  'background_image': 'https://media.rawg.io/bg.jpg',
                  'genres': <Map<String, dynamic>>[
                    {'name': 'RPG'}
                  ]
                }
              ]
            }),
            200,
          );
        }

        return http.Response('{}', 200);
      });

      final resilient = ResilientHttpClient(
        innerClient: mockClient,
        defaultTimeout: const Duration(seconds: 3),
      );
      SteamService.instance.setHttpClientForTesting(resilient);
      HltbService.instance.setHttpClientForTesting(resilient);
      MetadataService.instance.setHttpClientForTesting(resilient);

      final List<SyncProgress> progressEvents = [];
      final result = await SteamService.instance.syncWithDatabase(
        apiKey: 'test_key',
        steamId: '76561198000000000',
        onProgress: (p) => progressEvents.add(p),
      );

      expect(result.createdCount, equals(2));
      expect(result.processedCount, equals(2));
      expect(progressEvents.any((p) => p.phase == SyncPhase.savingCore), isTrue);
      expect(progressEvents.any((p) => p.phase == SyncPhase.completed), isTrue);

      final gamesInDb = await DatabaseService.instance.getAllGames();
      expect(gamesInDb.length, equals(2));

      final bg3 = gamesInDb.firstWhere((g) => g.steamId == 1086940);
      expect(bg3.title, equals("Baldur's Gate 3"));
      expect(bg3.hoursPlayed, equals(60.0));
      expect(bg3.hltbMain, equals(50.0));
      expect(bg3.status, equals('Jugado')); // 60h >= 50h HLTB -> Auto-culminado!
    });
  });
}
