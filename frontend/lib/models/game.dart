import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo de entidad de Videojuego optimizado para SQLite y persistencia local-first.
/// Incluye sanitización de límites defensivos de caracteres para garantizar
/// alta velocidad de indexación, serialización ultraligera y máxima eficiencia de memoria.
class Game {
  final String id;
  final String title;
  final String? coverUrl;
  final String status; // "Por jugar", "Jugando", "Jugado"
  final String? platform;
  final num? hoursPlayed;
  final List<String> genres;
  final String? rating; // "★" a "★★★★★"
  final num? hltbMain;
  final num? hltbCompletionist;
  final String? summary;
  final String? link;
  final DateTime? startDate;
  final DateTime? completedDate;
  final num? steamId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // --- Límites Defensivos de Optimización (Transparente para el Usuario) ---
  static const int maxTitleLength = 255;
  static const int maxPlatformLength = 100;
  static const int maxStatusLength = 50;
  static const int maxRatingLength = 20;
  static const int maxUrlLength = 2048;
  static const int maxSummaryLength = 2000;
  static const int maxGenreLength = 50;
  static const int maxGenresCount = 20;
  static const double maxPlaytimeHours = 99999.0;

  static String _truncate(String? val, int maxLen, {String fallback = ''}) {
    if (val == null) return fallback;
    final trimmed = val.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
  }

  static String? _truncateNullable(String? val, int maxLen) {
    if (val == null) return null;
    final trimmed = val.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
  }

  static num? _clampNum(num? val, {num min = 0.0, num max = maxPlaytimeHours}) {
    if (val == null) return null;
    if (val.isNaN || val.isInfinite) return 0.0;
    final clamped = val.clamp(min, max);
    return (clamped * 100).round() / 100;
  }

  static List<String> _sanitizeGenres(List<String> rawGenres) {
    return rawGenres
        .map((g) => _truncate(g, maxGenreLength))
        .where((g) => g.isNotEmpty)
        .take(maxGenresCount)
        .toList();
  }

  Game({
    String? id,
    required String title,
    String? coverUrl,
    String status = 'Por jugar',
    String? platform,
    num? hoursPlayed,
    List<String> genres = const [],
    String? rating,
    num? hltbMain,
    num? hltbCompletionist,
    String? summary,
    String? link,
    this.startDate,
    this.completedDate,
    num? steamId,
    this.createdAt,
    this.updatedAt,
    DateTime? lastEditedTime,
  })  : id = _truncate(id, 128, fallback: const Uuid().v4()),
        title = _truncate(title, maxTitleLength, fallback: 'Sin título'),
        coverUrl = _truncateNullable(coverUrl, maxUrlLength),
        status = _truncate(status, maxStatusLength, fallback: 'Por jugar'),
        platform = _truncateNullable(platform, maxPlatformLength),
        hoursPlayed = _clampNum(hoursPlayed),
        genres = _sanitizeGenres(genres),
        rating = _truncateNullable(rating, maxRatingLength),
        hltbMain = _clampNum(hltbMain),
        hltbCompletionist = _clampNum(hltbCompletionist),
        summary = _truncateNullable(summary, maxSummaryLength),
        link = _truncateNullable(link, maxUrlLength),
        steamId = steamId != null && steamId > 0 ? steamId.toInt() : null;

  /// Deserializa un registro directamente desde SQLite
  factory Game.fromSqliteMap(Map<String, dynamic> map) {
    List<String> parsedGenres = [];
    if (map['genres'] != null && map['genres'].toString().isNotEmpty) {
      try {
        final decoded = json.decode(map['genres'].toString());
        if (decoded is List) {
          parsedGenres = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedGenres = map['genres']
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return Game(
      id: map['id']?.toString(),
      title: map['title']?.toString() ?? 'Sin título',
      coverUrl: map['cover_url']?.toString(),
      status: map['status']?.toString() ?? 'Por jugar',
      platform: map['platform']?.toString(),
      hoursPlayed: map['hours_played'] as num?,
      genres: parsedGenres,
      rating: map['rating']?.toString(),
      hltbMain: map['hltb_main'] as num?,
      hltbCompletionist: map['hltb_completionist'] as num?,
      summary: map['summary']?.toString(),
      link: map['link']?.toString(),
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString())
          : null,
      completedDate: map['completed_date'] != null
          ? DateTime.tryParse(map['completed_date'].toString())
          : null,
      steamId: map['steam_id'] as num?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Serializa el objeto para inserción o actualización en SQLite
  Map<String, dynamic> toSqliteMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'status': status,
      'platform': platform,
      'hours_played': hoursPlayed ?? 0.0,
      'genres': json.encode(genres),
      'rating': rating,
      'hltb_main': hltbMain,
      'hltb_completionist': hltbCompletionist,
      'summary': summary,
      'link': link,
      'start_date': startDate != null
          ? "${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}"
          : null,
      'completed_date': completedDate != null
          ? "${completedDate!.year.toString().padLeft(4, '0')}-${completedDate!.month.toString().padLeft(2, '0')}-${completedDate!.day.toString().padLeft(2, '0')}"
          : null,
      'steam_id': steamId != null ? steamId!.toInt() : null,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': now,
    };
  }

  /// Serializa para respaldos JSON canónicos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'status': status,
      'platform': platform,
      'hours_played': hoursPlayed,
      'genres': genres,
      'rating': rating,
      'hltb_main': hltbMain,
      'hltb_completionist': hltbCompletionist,
      'summary': summary,
      'link': link,
      'start_date': startDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'steam_id': steamId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Deserializa desde JSON canónico
  factory Game.fromJson(Map<String, dynamic> json) {
    List<String> parsedGenres = [];
    if (json['genres'] != null) {
      if (json['genres'] is List) {
        parsedGenres = (json['genres'] as List).map((e) => e.toString()).toList();
      } else if (json['genres'] is String) {
        try {
          final decoded = jsonDecode(json['genres']);
          if (decoded is List) {
            parsedGenres = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedGenres = [json['genres'].toString()];
        }
      }
    }

    return Game(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Sin título',
      coverUrl: json['cover_url']?.toString(),
      status: json['status']?.toString() ?? 'Por jugar',
      platform: json['platform']?.toString(),
      hoursPlayed: json['hours_played'] as num?,
      genres: parsedGenres,
      rating: json['rating']?.toString(),
      hltbMain: json['hltb_main'] as num?,
      hltbCompletionist: json['hltb_completionist'] as num?,
      summary: json['summary']?.toString(),
      link: json['link']?.toString(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'].toString())
          : null,
      steamId: json['steam_id'] as num?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Deserializa registros legados de Notion para compatibilidad con respaldos antiguos
  factory Game.fromLegacyNotion(Map<String, dynamic> page) {
    final props = page['properties'] as Map<String, dynamic>? ?? {};

    String extractTitle(dynamic prop) {
      if (prop == null) return 'Sin título';
      final titleList = prop['title'] as List?;
      if (titleList != null && titleList.isNotEmpty) {
        return titleList[0]['plain_text'] ?? titleList[0]['text']?['content'] ?? 'Sin título';
      }
      return 'Sin título';
    }

    String? extractCover(dynamic prop) {
      if (prop == null) return null;
      final files = prop['files'] as List?;
      if (files != null && files.isNotEmpty) {
        final f = files[0];
        if (f['type'] == 'external') return f['external']?['url'];
        if (f['type'] == 'file') return f['file']?['url'];
      }
      return null;
    }

    String extractStatus(dynamic prop) {
      if (prop == null) return 'Por jugar';
      if (prop['status'] != null) return prop['status']['name'] ?? 'Por jugar';
      if (prop['select'] != null) return prop['select']['name'] ?? 'Por jugar';
      return 'Por jugar';
    }

    String? extractSelect(dynamic prop) {
      if (prop == null) return null;
      return prop['select']?['name'];
    }

    num? extractNumber(dynamic prop) {
      if (prop == null) return null;
      return prop['number'] as num?;
    }

    List<String> extractMultiSelect(dynamic prop) {
      if (prop == null) return [];
      final list = prop['multi_select'] as List?;
      if (list != null) {
        return list.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    String? extractRichText(dynamic prop) {
      if (prop == null) return null;
      final list = prop['rich_text'] as List?;
      if (list != null && list.isNotEmpty) {
        return list.map((e) => e['plain_text'] ?? '').join('');
      }
      return null;
    }

    String? extractUrl(dynamic prop) {
      if (prop == null) return null;
      return prop['url']?.toString();
    }

    DateTime? extractDate(dynamic prop) {
      if (prop == null) return null;
      final start = prop['date']?['start'];
      return start != null ? DateTime.tryParse(start.toString()) : null;
    }

    return Game(
      id: page['id']?.toString(),
      title: extractTitle(props['Título'] ?? props['Title'] ?? props['Name']),
      coverUrl: extractCover(props['Portada'] ?? props['Cover']),
      status: extractStatus(props['Estado'] ?? props['Status']),
      platform: extractSelect(props['Plataforma'] ?? props['Platform']),
      hoursPlayed: extractNumber(props['Horas Jugadas'] ?? props['Hours']),
      genres: extractMultiSelect(props['Géneros'] ?? props['Genres']),
      rating: extractSelect(props['Calificación'] ?? props['Rating']),
      hltbMain: extractNumber(props['HLTB Principal'] ?? props['HLTB Main']),
      hltbCompletionist: extractNumber(props['HLTB Completista'] ?? props['HLTB Completionist']),
      summary: extractRichText(props['Resumen'] ?? props['Summary']),
      link: extractUrl(props['Link'] ?? props['URL']),
      startDate: extractDate(props['Fecha de Inicio'] ?? props['Start Date']),
      completedDate: extractDate(props['Fecha de Culminación (primera campaña)'] ?? props['End Date']),
      steamId: extractNumber(props['Steam ID']),
      createdAt: DateTime.tryParse(page['created_time']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(page['last_edited_time']?.toString() ?? ''),
    );
  }

  static const Object _sentinel = Object();

  /// Clona el juego con campos actualizados respetando los límites defensivos
  /// y permitiendo asignar null explícito a campos opcionales para borrado o limpieza.
  Game copyWith({
    String? id,
    String? title,
    Object? coverUrl = _sentinel,
    String? status,
    Object? platform = _sentinel,
    num? hoursPlayed,
    List<String>? genres,
    Object? rating = _sentinel,
    Object? hltbMain = _sentinel,
    Object? hltbCompletionist = _sentinel,
    Object? summary = _sentinel,
    Object? link = _sentinel,
    Object? startDate = _sentinel,
    Object? completedDate = _sentinel,
    Object? steamId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: identical(coverUrl, _sentinel)
          ? this.coverUrl
          : (coverUrl as String?),
      status: status ?? this.status,
      platform: identical(platform, _sentinel)
          ? this.platform
          : (platform as String?),
      hoursPlayed: hoursPlayed ?? this.hoursPlayed,
      genres: genres ?? this.genres,
      rating: identical(rating, _sentinel)
          ? this.rating
          : (rating as String?),
      hltbMain: identical(hltbMain, _sentinel)
          ? this.hltbMain
          : (hltbMain as num?),
      hltbCompletionist: identical(hltbCompletionist, _sentinel)
          ? this.hltbCompletionist
          : (hltbCompletionist as num?),
      summary: identical(summary, _sentinel)
          ? this.summary
          : (summary as String?),
      link: identical(link, _sentinel)
          ? this.link
          : (link as String?),
      startDate: identical(startDate, _sentinel)
          ? this.startDate
          : (startDate as DateTime?),
      completedDate: identical(completedDate, _sentinel)
          ? this.completedDate
          : (completedDate as DateTime?),
      steamId: identical(steamId, _sentinel)
          ? this.steamId
          : (steamId as num?),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
