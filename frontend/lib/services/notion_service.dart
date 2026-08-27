import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cached response with TTL
class _CachedResponse {
  final dynamic data;
  final DateTime cachedAt;
  _CachedResponse(this.data) : cachedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inSeconds > 60;
}

/// Centralized Notion API service with rate limiting and in-memory cache.
class NotionService {
  static NotionService? _instance;
  String _token = '';
  String _gamesDbId = '';

  // Rate limiting: max 3 requests/second
  final Queue<Completer<http.Response>> _requestQueue = Queue();
  bool _isProcessingQueue = false;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _requestsThisSecond = 0;

  // In-memory cache
  final Map<String, _CachedResponse> _cache = {};

  static const String _baseUrl = 'https://api.notion.com/v1';
  static const String _notionVersion = '2022-06-28';

  NotionService._();

  static NotionService get instance {
    _instance ??= NotionService._();
    return _instance!;
  }

  void configure({required String token, required String gamesDbId}) {
    _token = token;
    _gamesDbId = gamesDbId;
    clearCache();
  }

  String get token => _token;
  String get gamesDbId => _gamesDbId;
  bool get isConfigured => _token.isNotEmpty && _gamesDbId.isNotEmpty;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Notion-Version': _notionVersion,
        'Content-Type': 'application/json',
      };

  void clearCache() {
    _cache.clear();
  }

  /// Validate the token by fetching the current user
  Future<bool> validateConnection() async {
    try {
      final response = await _makeRequest('GET', '/users/me');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Validate that we can access the database
  Future<bool> validateDatabase(String dbId) async {
    try {
      final response = await _makeRequest('GET', '/databases/$dbId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Query a database with optional filter and sorts
  Future<List<Map<String, dynamic>>> queryDatabase(
    String databaseId, {
    Map<String, dynamic>? filter,
    List<Map<String, dynamic>>? sorts,
    bool useCache = true,
  }) async {
    final cacheKey = 'query_${databaseId}_${filter?.hashCode}_${sorts?.hashCode}';

    if (useCache) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return List<Map<String, dynamic>>.from(cached.data);
      }
    }

    final List<Map<String, dynamic>> allResults = [];
    String? startCursor;
    bool hasMore = true;

    while (hasMore) {
      final body = <String, dynamic>{};
      if (filter != null) body['filter'] = filter;
      if (sorts != null) body['sorts'] = sorts;
      if (startCursor != null) body['start_cursor'] = startCursor;
      body['page_size'] = 100;

      final response = await _makeRequest(
        'POST',
        '/databases/$databaseId/query',
        body: body,
      );

      if (response.statusCode != 200) {
        throw NotionApiException(
          'Failed to query database: ${response.statusCode}',
          response.body,
        );
      }

      final data = json.decode(response.body);
      final results = (data['results'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      allResults.addAll(results);

      hasMore = data['has_more'] ?? false;
      startCursor = data['next_cursor'];
    }

    _cache[cacheKey] = _CachedResponse(allResults);
    return allResults;
  }

  static const String _persistentCacheKey = 'notion_persistent_games_cache_v1';

  /// Save raw games query to disk via SharedPreferences
  Future<void> saveLocalCache(List<Map<String, dynamic>> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(games);
      await prefs.setString(_persistentCacheKey, encoded);
    } catch (e) {
      // Ignore cache write errors
    }
  }

  /// Read cached games from disk (0ms offline load)
  Future<List<Map<String, dynamic>>?> getLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistentCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      // Ignore cache read errors
    }
    return null;
  }

  /// Get all games from the configured database with automatic persistent caching
  Future<List<Map<String, dynamic>>> getGames({bool useCache = true}) async {
    try {
      final results = await queryDatabase(
        _gamesDbId,
        sorts: [
          {
            'timestamp': 'last_edited_time',
            'direction': 'descending',
          }
        ],
        useCache: useCache,
      );
      // Asynchronously update disk cache
      unawaited(saveLocalCache(results));
      return results;
    } catch (e) {
      // Fallback to local cache if network/API fails
      final local = await getLocalCache();
      if (local != null && local.isNotEmpty) {
        return local;
      }
      rethrow;
    }
  }

  /// Create a new page in a database
  Future<Map<String, dynamic>> createPage(
    String databaseId,
    Map<String, dynamic> properties,
  ) async {
    final body = {
      'parent': {'database_id': databaseId},
      'properties': properties,
    };

    final response = await _makeRequest('POST', '/pages', body: body);

    if (response.statusCode != 200) {
      throw NotionApiException(
        'Failed to create page: ${response.statusCode}',
        response.body,
      );
    }

    // Invalidate cache for this database
    _cache.removeWhere((key, _) => key.contains(databaseId));

    return json.decode(response.body);
  }

  /// Convenience method to create a game directly in the configured database
  Future<Map<String, dynamic>> createGame(
    Map<String, dynamic> properties,
  ) async {
    return createPage(_gamesDbId, properties);
  }

  /// Update a page's properties
  Future<Map<String, dynamic>> updatePage(
    String pageId,
    Map<String, dynamic> properties,
  ) async {
    final body = {'properties': properties};
    final response = await _makeRequest('PATCH', '/pages/$pageId', body: body);

    if (response.statusCode != 200) {
      throw NotionApiException(
        'Failed to update page: ${response.statusCode}',
        response.body,
      );
    }

    // Invalidate all caches since we don't know which DB this page belongs to
    clearCache();

    return json.decode(response.body);
  }

  /// Archive (soft-delete) a page
  Future<void> deletePage(String pageId) async {
    final body = {'in_trash': true};
    final response = await _makeRequest('PATCH', '/pages/$pageId', body: body);

    if (response.statusCode != 200) {
      throw NotionApiException(
        'Failed to delete page: ${response.statusCode}',
        response.body,
      );
    }

    clearCache();
  }

  /// Rate-limited HTTP request handler
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // Rate limiting: wait if we've sent 3 requests this second
    final now = DateTime.now();
    if (now.difference(_lastRequestTime).inMilliseconds < 1000) {
      _requestsThisSecond++;
      if (_requestsThisSecond >= 3) {
        final waitMs = 1000 - now.difference(_lastRequestTime).inMilliseconds;
        if (waitMs > 0) {
          await Future.delayed(Duration(milliseconds: waitMs + 50));
        }
        _requestsThisSecond = 0;
      }
    } else {
      _requestsThisSecond = 0;
    }
    _lastRequestTime = DateTime.now();

    final uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;

    // Retry with exponential backoff
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        switch (method) {
          case 'GET':
            response = await http.get(uri, headers: _headers);
            break;
          case 'POST':
            response = await http.post(uri,
                headers: _headers, body: body != null ? json.encode(body) : null);
            break;
          case 'PATCH':
            response = await http.patch(uri,
                headers: _headers, body: body != null ? json.encode(body) : null);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        // If rate limited, retry with backoff
        if (response.statusCode == 429) {
          final retryAfter = int.tryParse(
                  response.headers['retry-after'] ?? '') ??
              (1 << attempt);
          await Future.delayed(Duration(seconds: retryAfter));
          continue;
        }

        return response;
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    throw Exception('Max retries exceeded');
  }
}

/// Custom exception for Notion API errors
class NotionApiException implements Exception {
  final String message;
  final String? responseBody;

  NotionApiException(this.message, [this.responseBody]);

  @override
  String toString() => 'NotionApiException: $message';
}
