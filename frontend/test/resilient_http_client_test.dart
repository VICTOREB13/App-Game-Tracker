import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tracker_app/services/resilient_http_client.dart';

void main() {
  group('ResilientHttpClient Unit Tests', () {
    test('GET request exitoso sin reintentos', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.url.toString(), equals('https://api.example.com/data?q=test'));
        return http.Response(json.encode({'status': 'ok'}), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final client = ResilientHttpClient(
        innerClient: mockClient,
        defaultTimeout: const Duration(seconds: 2),
      );

      final response = await client.get(Uri.https('api.example.com', '/data', {'q': 'test'}));
      expect(response.statusCode, equals(200));
      expect(requestCount, equals(1));
      final decoded = json.decode(response.body);
      expect(decoded['status'], equals('ok'));
    });

    test('POST request exitoso con payload JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        final body = json.decode(request.body);
        expect(body['name'], equals('Elden Ring'));
        return http.Response(json.encode({'id': 123}), 200);
      });

      final client = ResilientHttpClient(innerClient: mockClient);
      final response = await client.post(
        Uri.https('api.example.com', '/create'),
        body: json.encode({'name': 'Elden Ring'}),
      );

      expect(response.statusCode, equals(200));
    });

    test('Reintento automático ante HTTP 429 con backoff hasta éxito', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts < 3) {
          return http.Response('Rate limited', 429, headers: {'retry-after': '0'});
        }
        return http.Response(json.encode({'success': true}), 200);
      });

      final client = ResilientHttpClient(
        innerClient: mockClient,
        initialBackoff: const Duration(milliseconds: 10),
        defaultMaxRetries: 4,
      );

      final response = await client.get(Uri.https('api.example.com', '/rate-limited'));
      expect(response.statusCode, equals(200));
      expect(attempts, equals(3));
    });

    test('Reintento ante HTTP 500 y 503 hasta éxito', () async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) return http.Response('Server Error', 500);
        if (attempts == 2) return http.Response('Unavailable', 503);
        return http.Response('Recovered', 200);
      });

      final client = ResilientHttpClient(
        innerClient: mockClient,
        initialBackoff: const Duration(milliseconds: 10),
        defaultMaxRetries: 3,
      );

      final response = await client.get(Uri.https('api.example.com', '/server-error'));
      expect(response.statusCode, equals(200));
      expect(response.body, equals('Recovered'));
      expect(attempts, equals(3));
    });
  });
}
