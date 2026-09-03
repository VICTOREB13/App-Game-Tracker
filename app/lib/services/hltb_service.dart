import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'resilient_http_client.dart';
import 'string_normalizer.dart';

/// Modelo de resultados de tiempo de juego de HowLongToBeat
class HltbResult {
  final int gameId;
  final String gameName;
  final double? mainStory; // Horas para la historia principal
  final double? mainExtra; // Horas historia principal + extras
  final double? completionist; // Horas completista 100%

  const HltbResult({
    required this.gameId,
    required this.gameName,
    this.mainStory,
    this.mainExtra,
    this.completionist,
  });

  @override
  String toString() =>
      'HltbResult($gameName: Main=${mainStory}h, 100%=${completionist}h)';
}

/// Servicio nativo para consultar directamente los datos de duración
/// de HowLongToBeat (HLTB) sin requerir APIs de terceros.
class HltbService {
  static HltbService? _instance;
  ResilientHttpClient _httpClient;

  HltbService._({ResilientHttpClient? httpClient})
      : _httpClient = httpClient ?? ResilientHttpClient.instance;

  static HltbService get instance {
    _instance ??= HltbService._();
    return _instance!;
  }

  @visibleForTesting
  void setHttpClientForTesting(ResilientHttpClient client) {
    _httpClient = client;
  }

  // Caché de tokens de sesión para HLTB (válidos por 10 minutos)
  String? _token;
  String? _hpKey;
  String? _hpVal;
  DateTime? _tokenFetchedAt;
  Future<bool>? _authFuture;

  static const _baseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://howlongtobeat.com/',
    'Origin': 'https://howlongtobeat.com',
  };

  /// Obtiene o refresca los tokens de seguridad requeridos por HowLongToBeat
  /// protegido con memoización/mutex asíncrono para prevenir múltiples llamadas concurrentes
  Future<bool> _ensureAuthToken({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _token != null &&
        _tokenFetchedAt != null &&
        DateTime.now().difference(_tokenFetchedAt!).inMinutes < 10) {
      return true;
    }

    if (_authFuture != null) {
      return await _authFuture!;
    }

    _authFuture = _fetchAuthToken();
    try {
      final success = await _authFuture!;
      return success;
    } finally {
      _authFuture = null;
    }
  }

  Future<bool> _fetchAuthToken() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final initUri = Uri.https(
        'howlongtobeat.com',
        '/api/search/site/init',
        {'t': timestamp.toString()},
      );

      final res = await _httpClient.get(
        initUri,
        headers: _baseHeaders,
        timeout: const Duration(seconds: 8),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        _token = data['token']?.toString();
        _hpKey = data['hpKey']?.toString();
        _hpVal = data['hpVal']?.toString();
        _tokenFetchedAt = DateTime.now();
        return _token != null && _token!.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error inicializando token de HowLongToBeat: $e');
    }

    return false;
  }

  /// Limpia el título y extrae términos de búsqueda óptimos para HLTB
  List<String> _extractSearchTerms(String title) {
    // Usar StringNormalizer para eliminar símbolos molestos (™️, ®, :, etc.)
    final clean = StringNormalizer.cleanTitle(title);
    final terms = clean.split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (terms.isEmpty) {
      return title.split(' ').where((w) => w.trim().isNotEmpty).toList();
    }
    return terms;
  }

  /// Realiza la búsqueda de un videojuego en HowLongToBeat.
  /// Retorna las horas estimadas de Campaña y Completista.
  Future<HltbResult?> searchHltb(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    final terms = _extractSearchTerms(cleanTitle);
    if (terms.isEmpty) return null;

    return await _executeSearch(terms, cleanTitle, retryOn403: true);
  }

  Future<HltbResult?> _executeSearch(
    List<String> terms,
    String originalTitle, {
    required bool retryOn403,
  }) async {
    final hasAuth = await _ensureAuthToken();
    if (!hasAuth) {
      debugPrint('No se pudo autenticar con HowLongToBeat');
      return null;
    }

    final searchPayload = <String, dynamic>{
      'searchType': 'games',
      'searchTerms': terms,
      'searchPage': 1,
      'size': 5,
      'searchOptions': {
        'games': {
          'userId': 0,
          'platform': '',
          'sortCategory': 'popular',
          'rangeCategory': 'main',
          'rangeTime': {'min': null, 'max': null},
          'gameplay': {
            'perspective': '',
            'flow': '',
            'genre': '',
            'difficulty': ''
          },
          'rangeYear': {'min': '', 'max': ''},
          'modifier': ''
        },
        'users': {'sortCategory': 'postcount'},
        'lists': {'sortCategory': 'follows'},
        'filter': '',
        'sort': 0,
        'randomizer': 0
      },
      'useCache': true,
    };

    // Añadir el par clave/valor de seguridad dinámico de HLTB
    if (_hpKey != null && _hpKey!.isNotEmpty && _hpVal != null) {
      searchPayload[_hpKey!] = _hpVal;
    }

    final searchHeaders = Map<String, String>.from(_baseHeaders)
      ..addAll({
        'Content-Type': 'application/json',
        'x-auth-token': _token ?? '',
        if (_hpKey != null) 'x-hp-key': _hpKey!,
        if (_hpVal != null) 'x-hp-val': _hpVal!,
      });

    try {
      final searchUri = Uri.https('howlongtobeat.com', '/api/search/site');
      final res = await _httpClient.post(
        searchUri,
        headers: searchHeaders,
        body: json.encode(searchPayload),
        timeout: const Duration(seconds: 10),
      );

      if (res.statusCode == 403 && retryOn403) {
        // Token expirado en el servidor; refrescar forzosamente y reintentar
        await _ensureAuthToken(forceRefresh: true);
        return await _executeSearch(terms, originalTitle, retryOn403: false);
      }

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List?;
        if (list == null || list.isEmpty) {
          return null;
        }

        // Buscar la mejor coincidencia entre los resultados devueltos
        Map<String, dynamic>? bestMatch;
        double bestSimilarity = -1.0;
        final cleanQuery = StringNormalizer.cleanTitle(originalTitle);

        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final gameName = map['game_name']?.toString() ?? '';
          final cleanFound = StringNormalizer.cleanTitle(gameName);
          final sim = StringNormalizer.similarity(cleanQuery, cleanFound);

          if (sim > bestSimilarity) {
            bestSimilarity = sim;
            bestMatch = map;
          }
        }

        bestMatch ??= list.first as Map<String, dynamic>;

        final gameId = (bestMatch['game_id'] as num?)?.toInt() ?? 0;
        final gameName = bestMatch['game_name']?.toString() ?? originalTitle;

        // Los tiempos vienen expresados en segundos en la API de HLTB
        final rawMain = (bestMatch['comp_main'] as num?)?.toDouble() ?? 0.0;
        final rawPlus = (bestMatch['comp_plus'] as num?)?.toDouble() ?? 0.0;
        final raw100 = (bestMatch['comp_100'] as num?)?.toDouble() ?? 0.0;

        // Convertir a horas y redondear a 1 decimal
        final mainHours = rawMain > 0
            ? double.parse((rawMain / 3600.0).toStringAsFixed(1))
            : null;
        final plusHours = rawPlus > 0
            ? double.parse((rawPlus / 3600.0).toStringAsFixed(1))
            : null;
        final compHours = raw100 > 0
            ? double.parse((raw100 / 3600.0).toStringAsFixed(1))
            : null;

        return HltbResult(
          gameId: gameId,
          gameName: gameName,
          mainStory: mainHours,
          mainExtra: plusHours,
          completionist: compHours,
        );
      }
    } catch (e) {
      debugPrint('Error buscando en HowLongToBeat ($originalTitle): $e');
    }

    return null;
  }
}
