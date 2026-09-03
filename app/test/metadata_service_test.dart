import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/services/hltb_service.dart';
import 'package:tracker_app/services/metadata_service.dart';
import 'package:tracker_app/services/resilient_http_client.dart';

void main() {
  group('MetadataService Tests', () {
    test('searchWikipedia con MockClient encuentra enlaces canónicos sanitizados', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('wikipedia.org')) {
          final query = request.url.queryParameters['srsearch'] ?? '';
          if (query.contains('Hollow Knight')) {
            return http.Response(
              json.encode({
                'query': {
                  'search': [
                    {'title': 'Hollow Knight'}
                  ]
                }
              }),
              200,
            );
          }
        }
        return http.Response('{}', 200);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      MetadataService.instance.setHttpClientForTesting(resilient);

      final wikiUrl = await MetadataService.instance.searchWikipedia('Hollow Knight™');
      expect(wikiUrl, isNotNull);
      expect(wikiUrl, contains('wikipedia.org/wiki/'));
      expect(wikiUrl, contains('Hollow_Knight'));
    });

    test('searchRawg obtiene cover_url y lista de géneros sin filtrar', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('rawg.io')) {
          expect(request.url.queryParameters['key'], equals('fake_rawg_key'));
          return http.Response(
            json.encode({
              'results': [
                {
                  'background_image': 'https://media.rawg.io/media/games/hades.jpg',
                  'genres': [
                    {'name': 'Roguelike'},
                    {'name': 'Action'},
                    {'name': 'Indie'}
                  ]
                }
              ]
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      MetadataService.instance.setHttpClientForTesting(resilient);

      final data = await MetadataService.instance.searchRawg('Hades', 'fake_rawg_key');
      expect(data, isNotNull);
      expect(data!['cover_url'], equals('https://media.rawg.io/media/games/hades.jpg'));
      expect(data['genres'], equals(['Roguelike', 'Action', 'Indie']));
    });

    test('searchRawgGames busca catálogo paginado a través de ResilientHttpClient', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('rawg.io') && request.url.path == '/api/games') {
          expect(request.url.queryParameters['search'], equals('Zelda'));
          expect(request.url.queryParameters['page_size'], equals('5'));
          return http.Response(
            json.encode({
              'results': [
                {'id': 1, 'name': 'The Legend of Zelda: Tears of the Kingdom'},
                {'id': 2, 'name': 'The Legend of Zelda: Breath of the Wild'},
              ]
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      MetadataService.instance.setHttpClientForTesting(resilient);

      final games = await MetadataService.instance.searchRawgGames('Zelda', 'fake_key', pageSize: 5);
      expect(games.length, equals(2));
      expect(games.first['name'], equals('The Legend of Zelda: Tears of the Kingdom'));
    });

    test('syncAllHltbGames retorna contadores en 0 si no hay juegos pendientes', () async {
      final games = [
        Game(
          id: '1',
          title: 'Zelda',
          hltbMain: 50.0,
          hltbCompletionist: 120.0,
        ),
      ];

      final result = await MetadataService.instance.syncAllHltbGames(games: games);
      expect(result['total'], equals(0));
      expect(result['updated'], equals(0));
      expect(result['failed'], equals(0));
    });

    test('syncAllHltbGames procesa juegos pendientes e invoca onProgress', () async {
      final mockClient = MockClient((request) async {
        return http.Response('[]', 200);
      });
      HltbService.instance.setHttpClientForTesting(ResilientHttpClient(innerClient: mockClient));

      final games = [
        Game(
          id: '1',
          title: 'Hollow Knight',
          hltbMain: null,
          hltbCompletionist: null,
        ),
      ];

      final progressCalls = <String>[];
      final result = await MetadataService.instance.syncAllHltbGames(
        games: games,
        onProgress: (cur, tot, title) => progressCalls.add('$cur/$tot: $title'),
      );

      expect(result['total'], equals(1));
      expect(progressCalls, equals(['1/1: Hollow Knight']));
    });

    test('syncAllGamesMetadata retorna contadores en 0 si no hay juegos pendientes', () async {
      final games = [
        Game(
          id: '1',
          title: 'Zelda',
          genres: ['Aventura'],
          coverUrl: 'https://example.com/cover.jpg',
          link: 'https://es.wikipedia.org/wiki/Zelda',
        ),
      ];

      final result = await MetadataService.instance.syncAllGamesMetadata(
        games: games,
        rawgKey: 'test_key',
      );
      expect(result['total'], equals(0));
      expect(result['updated'], equals(0));
      expect(result['failed'], equals(0));
    });

    test('syncAllGamesMetadata invoca onProgress y procesa lista pendiente', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });
      final resilient = ResilientHttpClient(innerClient: mockClient);
      MetadataService.instance.setHttpClientForTesting(resilient);
      HltbService.instance.setHttpClientForTesting(resilient);

      final games = [
        Game(
          id: '2',
          title: 'Celeste',
          genres: [],
          coverUrl: null,
          link: null,
          hltbMain: 10,
          hltbCompletionist: 30,
        ),
      ];

      final progressCalls = <String>[];
      final result = await MetadataService.instance.syncAllGamesMetadata(
        games: games,
        rawgKey: 'fake_key',
        onProgress: (cur, tot, title) => progressCalls.add('$cur/$tot: $title'),
      );

      expect(result['total'], equals(1));
      expect(progressCalls, equals(['1/1: Celeste']));
    });
  });
}
