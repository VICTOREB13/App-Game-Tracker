import '../models/game.dart';

/// Servicio de parseo desacoplado para deserializar registros heredados de Notion API (v2.x).
class NotionParser {
  /// Parsea una página de Notion a una entidad pura [Game].
  static Game parsePage(Map<String, dynamic> page) => parseLegacyPage(page);

  /// Deserializa registros legados de Notion para compatibilidad con respaldos antiguos.
  static Game parseLegacyPage(Map<String, dynamic> page) {
    final props = page['properties'] as Map<String, dynamic>? ?? {};

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
      hltbCompletionist:
          extractNumber(props['HLTB Completista'] ?? props['HLTB Completionist']),
      summary: extractRichText(props['Resumen'] ?? props['Summary']),
      link: extractUrl(props['Link'] ?? props['URL']),
      startDate: extractDate(props['Fecha de Inicio'] ?? props['Start Date']),
      completedDate: extractDate(
          props['Fecha de Culminación (primera campaña)'] ?? props['End Date']),
      steamId: extractNumber(props['Steam ID']),
      createdAt: DateTime.tryParse(page['created_time']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(page['last_edited_time']?.toString() ?? ''),
    );
  }

  /// Extrae el título principal de una propiedad Notion
  static String extractTitle(dynamic prop) {
    if (prop == null) {
      return 'Sin título';
    }
    final p = prop as Map<String, dynamic>?;
    final titleList = p?['title'] as List?;
    if (titleList != null && titleList.isNotEmpty) {
      final first = titleList[0] as Map<String, dynamic>?;
      return first?['plain_text']?.toString() ??
          (first?['text'] as Map<String, dynamic>?)?['content']?.toString() ??
          'Sin título';
    }
    return 'Sin título';
  }

  /// Extrae la URL de portada desde una propiedad de archivos de Notion
  static String? extractCover(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    final files = p?['files'] as List?;
    if (files != null && files.isNotEmpty) {
      final f = files[0] as Map<String, dynamic>?;
      if (f != null) {
        if (f['type'] == 'external') {
          final externalMap = f['external'] as Map<String, dynamic>?;
          return externalMap?['url'] as String?;
        }
        if (f['type'] == 'file') {
          final fileMap = f['file'] as Map<String, dynamic>?;
          return fileMap?['url'] as String?;
        }
      }
    }
    return null;
  }

  /// Extrae el estado del juego resolviendo select o status de Notion
  static String extractStatus(dynamic prop) {
    if (prop == null) {
      return 'Por jugar';
    }
    final p = prop as Map<String, dynamic>?;
    if (p?['status'] != null) {
      final statusMap = p!['status'] as Map<String, dynamic>?;
      return statusMap?['name']?.toString() ?? 'Por jugar';
    }
    if (p?['select'] != null) {
      final selectMap = p!['select'] as Map<String, dynamic>?;
      return selectMap?['name']?.toString() ?? 'Por jugar';
    }
    return 'Por jugar';
  }

  /// Extrae el valor seleccionado de una propiedad select
  static String? extractSelect(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    final selectMap = p?['select'] as Map<String, dynamic>?;
    return selectMap?['name']?.toString();
  }

  /// Extrae un número de una propiedad number
  static num? extractNumber(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    return p?['number'] as num?;
  }

  /// Extrae una lista de nombres de una propiedad multi_select
  static List<String> extractMultiSelect(dynamic prop) {
    if (prop == null) {
      return const [];
    }
    final p = prop as Map<String, dynamic>?;
    final list = p?['multi_select'] as List?;
    if (list != null) {
      return list
          .map((e) => (e as Map<String, dynamic>?)?['name']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Concatena texto enriquecido de una propiedad rich_text
  static String? extractRichText(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    final list = p?['rich_text'] as List?;
    if (list != null && list.isNotEmpty) {
      return list
          .map((e) =>
              (e as Map<String, dynamic>?)?['plain_text']?.toString() ?? '')
          .join('');
    }
    return null;
  }

  /// Extrae una URL directa de una propiedad url
  static String? extractUrl(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    return p?['url']?.toString();
  }

  /// Parsea la fecha de inicio de una propiedad date
  static DateTime? extractDate(dynamic prop) {
    if (prop == null) {
      return null;
    }
    final p = prop as Map<String, dynamic>?;
    final dateMap = p?['date'] as Map<String, dynamic>?;
    final start = dateMap?['start'];
    return start != null ? DateTime.tryParse(start.toString()) : null;
  }
}
