import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tracker_app/services/hltb_service.dart';
import 'package:tracker_app/services/resilient_http_client.dart';

void main() {
  group('HowLongToBeat Service Tests', () {
    test('HltbResult almacena correctamente horas de campaña y completista', () {
      const result = HltbResult(
        gameId: 26286,
        gameName: 'Hollow Knight',
        mainStory: 27.0,
        mainExtra: 41.5,
        completionist: 65.5,
      );

      expect(result.gameId, equals(26286));
      expect(result.gameName, equals('Hollow Knight'));
      expect(result.mainStory, equals(27.0));
      expect(result.mainExtra, equals(41.5));
      expect(result.completionist, equals(65.5));
    });

    test('searchHltb con MockClient offline extrae tiempos y parsea horas', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/search/site/init')) {
          return http.Response(
            json.encode({
              'token': 'auth_token_123',
              'hpKey': 'x-hp-key-custom',
              'hpVal': 'custom-val-data',
            }),
            200,
          );
        }

        if (request.url.path.contains('/api/search/site')) {
          expect(request.headers['x-auth-token'], equals('auth_token_123'));
          expect(request.headers['x-hp-key-custom'], equals('custom-val-data'));

          return http.Response(
            json.encode({
              'data': [
                {
                  'game_id': 620,
                  'game_name': 'Portal 2',
                  'comp_main': 30600, // 8.5 horas
                  'comp_plus': 46800, // 13.0 horas
                  'comp_100': 79200, // 22.0 horas
                }
              ]
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final resilient = ResilientHttpClient(innerClient: mockClient);
      HltbService.instance.setHttpClientForTesting(resilient);

      final result = await HltbService.instance.searchHltb('Portal 2');
      expect(result, isNotNull);
      expect(result!.gameName, equals('Portal 2'));
      expect(result.mainStory, equals(8.5));
      expect(result.mainExtra, equals(13.0));
      expect(result.completionist, equals(22.0));
    });
  });
}
