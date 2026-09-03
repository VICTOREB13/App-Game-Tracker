import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../services/notion_parser.dart';
import 'game_sanitizer.dart';

export 'game_sanitizer.dart';

/// Modelo de entidad de Videojuego optimizado para persistencia SQLite local-first.
class Game {
  final String id, title, status;
  final String? coverUrl, platform, rating, summary, link;
  final num? hoursPlayed, hltbMain, hltbCompletionist, steamId;
  final List<String> genres;
  final DateTime? startDate, completedDate, createdAt, updatedAt;

  // Límites defensivos delegados en GameSanitizer para compatibilidad
  static const int maxTitleLength = GameSanitizer.maxTitleLength;
  static const int maxPlatformLength = GameSanitizer.maxPlatformLength;
  static const int maxStatusLength = GameSanitizer.maxStatusLength;
  static const int maxRatingLength = GameSanitizer.maxRatingLength;
  static const int maxUrlLength = GameSanitizer.maxUrlLength;
  static const int maxSummaryLength = GameSanitizer.maxSummaryLength;
  static const int maxGenreLength = GameSanitizer.maxGenreLength;
  static const int maxGenresCount = GameSanitizer.maxGenresCount;
  static const double maxPlaytimeHours = GameSanitizer.maxPlaytimeHours;

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
  })  : id = GameSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        title = GameSanitizer.truncate(title, maxTitleLength, fallback: 'Sin título'),
        coverUrl = GameSanitizer.truncateNullable(coverUrl, maxUrlLength),
        status = GameSanitizer.truncate(status, maxStatusLength, fallback: 'Por jugar'),
        platform = GameSanitizer.truncateNullable(platform, maxPlatformLength),
        hoursPlayed = GameSanitizer.clampNum(hoursPlayed),
        genres = GameSanitizer.sanitizeGenres(genres),
        rating = GameSanitizer.truncateNullable(rating, maxRatingLength),
        hltbMain = GameSanitizer.clampNum(hltbMain),
        hltbCompletionist = GameSanitizer.clampNum(hltbCompletionist),
        summary = GameSanitizer.truncateNullable(summary, maxSummaryLength),
        link = GameSanitizer.truncateNullable(link, maxUrlLength),
        steamId = steamId != null && steamId > 0 ? steamId.toInt() : null;

  /// Deserializa directamente desde SQLite delegando en [fromJson]
  factory Game.fromSqliteMap(Map<String, dynamic> map) => Game.fromJson(map);

  /// Serializa el objeto para inserción o actualización en SQLite
  Map<String, dynamic> toSqliteMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id, 'title': title, 'cover_url': coverUrl, 'status': status,
      'platform': platform, 'hours_played': hoursPlayed ?? 0.0,
      'genres': json.encode(genres), 'rating': rating, 'hltb_main': hltbMain,
      'hltb_completionist': hltbCompletionist, 'summary': summary, 'link': link,
      'start_date': GameSanitizer.formatIsoDate(startDate),
      'completed_date': GameSanitizer.formatIsoDate(completedDate),
      'steam_id': steamId?.toInt(),
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
    };
  }

  /// Serializa para respaldos JSON canónicos
  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'cover_url': coverUrl, 'status': status,
        'platform': platform, 'hours_played': hoursPlayed, 'genres': genres,
        'rating': rating, 'hltb_main': hltbMain, 'hltb_completionist': hltbCompletionist,
        'summary': summary, 'link': link, 'start_date': startDate?.toIso8601String(),
        'completed_date': completedDate?.toIso8601String(), 'steam_id': steamId,
        'created_at': createdAt?.toIso8601String(), 'updated_at': updatedAt?.toIso8601String(),
      };

  /// Deserializa desde JSON canónico
  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id']?.toString(),
        title: json['title']?.toString() ?? 'Sin título',
        coverUrl: json['cover_url']?.toString(),
        status: json['status']?.toString() ?? 'Por jugar',
        platform: json['platform']?.toString(),
        hoursPlayed: json['hours_played'] as num?,
        genres: GameSanitizer.parseGenres(json['genres']),
        rating: json['rating']?.toString(),
        hltbMain: json['hltb_main'] as num?,
        hltbCompletionist: json['hltb_completionist'] as num?,
        summary: json['summary']?.toString(),
        link: json['link']?.toString(),
        startDate: GameSanitizer.parseDate(json['start_date']),
        completedDate: GameSanitizer.parseDate(json['completed_date']),
        steamId: json['steam_id'] as num?,
        createdAt: GameSanitizer.parseDate(json['created_at']),
        updatedAt: GameSanitizer.parseDate(json['updated_at']),
      );

  /// Deserializa registros legados de Notion delegando en [NotionParser]
  factory Game.fromLegacyNotion(Map<String, dynamic> page) =>
      NotionParser.parseLegacyPage(page);

  static const Object _sentinel = Object();

  /// Clona el juego con campos actualizados respetando los límites defensivos
  Game copyWith({
    String? id, String? title, Object? coverUrl = _sentinel, String? status,
    Object? platform = _sentinel, Object? hoursPlayed = _sentinel, Object? genres = _sentinel,
    Object? rating = _sentinel, Object? hltbMain = _sentinel,
    Object? hltbCompletionist = _sentinel, Object? summary = _sentinel,
    Object? link = _sentinel, Object? startDate = _sentinel,
    Object? completedDate = _sentinel, Object? steamId = _sentinel,
    Object? createdAt = _sentinel, Object? updatedAt = _sentinel,
  }) {
    List<String> resolvedGenres;
    if (identical(genres, _sentinel)) {
      resolvedGenres = this.genres;
    } else if (genres is List<String>) {
      resolvedGenres = genres;
    } else if (genres is List) {
      resolvedGenres = genres.map((e) => e.toString()).toList();
    } else {
      resolvedGenres = const [];
    }

    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: identical(coverUrl, _sentinel) ? this.coverUrl : (coverUrl as String?),
      status: status ?? this.status,
      platform: identical(platform, _sentinel) ? this.platform : (platform as String?),
      hoursPlayed: identical(hoursPlayed, _sentinel) ? this.hoursPlayed : (hoursPlayed as num?),
      genres: resolvedGenres,
      rating: identical(rating, _sentinel) ? this.rating : (rating as String?),
      hltbMain: identical(hltbMain, _sentinel) ? this.hltbMain : (hltbMain as num?),
      hltbCompletionist: identical(hltbCompletionist, _sentinel) ? this.hltbCompletionist : (hltbCompletionist as num?),
      summary: identical(summary, _sentinel) ? this.summary : (summary as String?),
      link: identical(link, _sentinel) ? this.link : (link as String?),
      startDate: identical(startDate, _sentinel) ? this.startDate : (startDate as DateTime?),
      completedDate: identical(completedDate, _sentinel) ? this.completedDate : (completedDate as DateTime?),
      steamId: identical(steamId, _sentinel) ? this.steamId : (steamId as num?),
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : (createdAt as DateTime?),
      updatedAt: identical(updatedAt, _sentinel) ? this.updatedAt : (updatedAt as DateTime?),
    );
  }

  /// Aplica progreso de horas jugadas y ejecuta transiciones automáticas de estado
  Game applyPlaytimeProgress({num? additionalHours, num? totalHours}) {
    final num newHours =
        totalHours ?? ((hoursPlayed ?? 0) + (additionalHours ?? 0));
    String newStatus = status;
    DateTime? newStartDate = startDate;
    DateTime? newCompletedDate = completedDate;

    if (hltbMain != null &&
        hltbMain! > 0 &&
        newHours >= hltbMain! &&
        status != 'Jugado') {
      newStatus = 'Jugado';
      newCompletedDate ??= DateTime.now();
    } else if (status == 'Por jugar' && newHours >= 1.0) {
      newStatus = 'Jugando';
      newStartDate ??= DateTime.now();
    }

    return copyWith(
      hoursPlayed: newHours,
      status: newStatus,
      startDate: newStartDate,
      completedDate: newCompletedDate,
      updatedAt: DateTime.now(),
    );
  }
}
