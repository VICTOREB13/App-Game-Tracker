import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP con pool de conexiones persistente, timeouts defensivos
/// y reintentos automáticos con retroceso exponencial (exponential backoff)
/// ante errores de saturación (429) o fallos de servidor (500, 502, 503, 504).
class ResilientHttpClient {
  static ResilientHttpClient? _instance;
  http.Client _innerClient;

  final Duration defaultTimeout;
  final int defaultMaxRetries;
  final Duration initialBackoff;
  final double backoffMultiplier;
  final Duration maxBackoff;

  ResilientHttpClient({
    http.Client? innerClient,
    this.defaultTimeout = const Duration(seconds: 10),
    this.defaultMaxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxBackoff = const Duration(seconds: 8),
  }) : _innerClient = innerClient ?? http.Client();

  static ResilientHttpClient get instance {
    _instance ??= ResilientHttpClient();
    return _instance!;
  }

  /// Permite inyectar un MockClient para pruebas unitarias deterministas
  @visibleForTesting
  void setClientForTesting(http.Client client) {
    _innerClient = client;
  }

  /// Ejecuta una petición GET con reintentos y retroceso exponencial
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _innerClient.get(url, headers: headers),
      url: url,
      method: 'GET',
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? defaultMaxRetries,
    );
  }

  /// Ejecuta una petición POST con reintentos y retroceso exponencial
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _innerClient.post(url, headers: headers, body: body, encoding: encoding),
      url: url,
      method: 'POST',
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? defaultMaxRetries,
    );
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() requestFn, {
    required Uri url,
    required String method,
    required Duration timeout,
    required int maxRetries,
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        final response = await requestFn().timeout(timeout);

        if (_shouldRetryStatusCode(response.statusCode) && attempt <= maxRetries) {
          final delay = _calculateBackoff(attempt, response);
          debugPrint(
            '[ResilientHttpClient] $method ${url.host}${url.path} retornó ${response.statusCode}. '
            'Reintentando ($attempt/$maxRetries) en ${delay.inMilliseconds}ms...',
          );
          await Future<void>.delayed(delay);
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt <= maxRetries) {
          final delay = _calculateBackoff(attempt, null);
          debugPrint(
            '[ResilientHttpClient] Timeout en $method $url. '
            'Reintentando ($attempt/$maxRetries) en ${delay.inMilliseconds}ms...',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        rethrow;
      } on SocketException catch (e) {
        if (attempt <= maxRetries) {
          final delay = _calculateBackoff(attempt, null);
          debugPrint(
            '[ResilientHttpClient] SocketException en $method $url: $e. '
            'Reintentando ($attempt/$maxRetries) en ${delay.inMilliseconds}ms...',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        rethrow;
      } on http.ClientException catch (e) {
        if (attempt <= maxRetries) {
          final delay = _calculateBackoff(attempt, null);
          debugPrint(
            '[ResilientHttpClient] ClientException en $method $url: $e. '
            'Reintentando ($attempt/$maxRetries) en ${delay.inMilliseconds}ms...',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  bool _shouldRetryStatusCode(int statusCode) {
    return statusCode == 429 || // Too Many Requests / Rate Limited
        statusCode == 500 || // Internal Server Error
        statusCode == 502 || // Bad Gateway
        statusCode == 503 || // Service Unavailable
        statusCode == 504; // Gateway Timeout
  }

  Duration _calculateBackoff(int attempt, http.Response? response) {
    if (response != null && response.statusCode == 429) {
      final retryAfterHeader = response.headers['retry-after'];
      if (retryAfterHeader != null) {
        final retrySeconds = int.tryParse(retryAfterHeader);
        if (retrySeconds != null && retrySeconds > 0) {
          return Duration(seconds: retrySeconds);
        }
      }
    }

    final exponentialMs = initialBackoff.inMilliseconds *
        math.pow(backoffMultiplier, attempt - 1).toDouble();
    final clampedMs = math.min(exponentialMs, maxBackoff.inMilliseconds.toDouble());
    return Duration(milliseconds: clampedMs.round());
  }

  void close() {
    _innerClient.close();
  }
}
