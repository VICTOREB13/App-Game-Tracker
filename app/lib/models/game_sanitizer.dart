import 'dart:convert';

/// Límites defensivos y funciones de sanitización para el modelo Game.
class GameSanitizer {
  // Constantes de límites defensivos
  static const int maxTitleLength = 255;
  static const int maxPlatformLength = 100;
  static const int maxStatusLength = 50;
  static const int maxRatingLength = 20;
  static const int maxUrlLength = 2048;
  static const int maxSummaryLength = 2000;
  static const int maxGenreLength = 50;
  static const int maxGenresCount = 20;
  static const double maxPlaytimeHours = 99999.0;

  /// Trunca una cadena respetando un límite máximo y proveyendo un fallback si es nula o vacía
  static String truncate(String? val, int maxLen, {String fallback = ''}) {
    if (val == null) {
      return fallback;
    }
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
  }

  /// Trunca una cadena opcional preservando null si la cadena es nula o vacía
  static String? truncateNullable(String? val, int maxLen) {
    if (val == null) {
      return null;
    }
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
  }

  /// Limita un valor numérico entre un mínimo y un máximo, redondeando a 2 decimales
  static num? clampNum(num? val, {num min = 0.0, num max = maxPlaytimeHours}) {
    if (val == null) {
      return null;
    }
    if (val.isNaN || val.isInfinite) {
      return 0.0;
    }
    final clamped = val.clamp(min, max);
    return (clamped * 100).round() / 100;
  }

  /// Sanitiza una lista de géneros truncando cada uno y limitando la cantidad máxima
  static List<String> sanitizeGenres(List<String> rawGenres) {
    return rawGenres
        .map((g) => truncate(g, maxGenreLength))
        .where((g) => g.isNotEmpty)
        .take(maxGenresCount)
        .toList();
  }

  /// Parsea valores de fecha ISO-8601 de forma segura
  static DateTime? parseDate(dynamic raw) =>
      raw != null ? DateTime.tryParse(raw.toString()) : null;

  /// Formatea DateTime a cadena corta ISO YYYY-MM-DD para SQLite
  static String? formatIsoDate(DateTime? d) => d != null
      ? '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
      : null;

  /// Parsea géneros desde List, JSON array codificado o lista separada por comas
  static List<String> parseGenres(dynamic raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }
}
