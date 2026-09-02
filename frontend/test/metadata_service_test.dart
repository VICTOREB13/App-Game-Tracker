import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  });
}
