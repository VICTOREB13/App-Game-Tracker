import '../services/notion_parser.dart';

class Game {
  final String notionPageId;
  final String title;
  final String? coverUrl;
  final String status; // "Por jugar", "Jugando", "Jugado"
  final String? platform;
  final num? hoursPlayed;
  final List<String> genres;
  final String? rating; // "★★★★★", etc.
  final num? hltbMain;
  final num? hltbCompletionist;
  final String? summary;
  final String? link;
  final DateTime? startDate;
  final DateTime? completedDate;
  final num? steamId;
  final DateTime? lastEditedTime;

  Game({
    required this.notionPageId,
    required this.title,
    this.coverUrl,
    this.status = 'Por jugar',
    this.platform,
    this.hoursPlayed,
    this.genres = const [],
    this.rating,
    this.hltbMain,
    this.hltbCompletionist,
    this.summary,
    this.link,
    this.startDate,
    this.completedDate,
    this.steamId,
    this.lastEditedTime,
  });

  /// Parse a Notion page object into a Game
  factory Game.fromNotionPage(Map<String, dynamic> page) {
    final props = page['properties'] as Map<String, dynamic>;

    return Game(
      notionPageId: page['id'] ?? '',
      title: NotionParser.parseTitle(props['Título']),
      coverUrl: NotionParser.parseFiles(props['Portada']),
      status: NotionParser.parseStatus(props['Estado']),
      platform: NotionParser.parseSelect(props['Plataforma']),
      hoursPlayed: NotionParser.parseNumber(props['Horas Jugadas']),
      genres: NotionParser.parseMultiSelect(props['Géneros']),
      rating: NotionParser.parseSelect(props['Calificación']),
      hltbMain: NotionParser.parseNumber(props['HLTB Principal']),
      hltbCompletionist: NotionParser.parseNumber(props['HLTB Completista']),
      summary: NotionParser.parseRichText(props['Resumen']),
      link: NotionParser.parseUrl(props['Link']),
      startDate: NotionParser.parseDate(props['Fecha de Inicio']),
      completedDate: NotionParser.parseDate(
          props['Fecha de Culminación (primera campaña)']),
      steamId: NotionParser.parseNumber(props['Steam ID']),
      lastEditedTime: DateTime.tryParse(page['last_edited_time'] ?? ''),
    );
  }

  /// Build Notion properties map for creating/updating a page
  Map<String, dynamic> toNotionProperties({
    bool includeTitle = true,
    bool includeCover = true,
  }) {
    final props = <String, dynamic>{};

    if (includeTitle) {
      props['Título'] = NotionParser.buildTitle(title);
    }

    props['Estado'] = NotionParser.buildStatus(status);
    props['Plataforma'] = NotionParser.buildSelect(platform);
    props['Horas Jugadas'] = NotionParser.buildNumber(hoursPlayed);
    props['Géneros'] = NotionParser.buildMultiSelect(genres);
    props['Calificación'] = NotionParser.buildSelect(rating);

    if (hltbMain != null) {
      props['HLTB Principal'] = NotionParser.buildNumber(hltbMain);
    }

    if (hltbCompletionist != null) {
      props['HLTB Completista'] = NotionParser.buildNumber(hltbCompletionist);
    }

    props['Resumen'] = NotionParser.buildRichText(summary);
    props['Link'] = NotionParser.buildUrl(link);
    props['Fecha de Inicio'] = NotionParser.buildDate(startDate);
    props['Fecha de Culminación (primera campaña)'] =
        NotionParser.buildDate(completedDate);

    if (includeCover && coverUrl != null && coverUrl!.isNotEmpty) {
      final isNotionHosted = coverUrl!.contains('amazonaws.com') ||
          coverUrl!.contains('prod-files-secure') ||
          coverUrl!.contains('notion-static.com');
      if (!isNotionHosted) {
        props['Portada'] = NotionParser.buildExternalFile(coverUrl);
      }
    }

    return props;
  }

  /// Create a copy with updated fields
  Game copyWith({
    String? notionPageId,
    String? title,
    String? coverUrl,
    String? status,
    String? platform,
    num? hoursPlayed,
    List<String>? genres,
    String? rating,
    num? hltbMain,
    num? hltbCompletionist,
    String? summary,
    String? link,
    DateTime? startDate,
    DateTime? completedDate,
    num? steamId,
  }) {
    return Game(
      notionPageId: notionPageId ?? this.notionPageId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      hoursPlayed: hoursPlayed ?? this.hoursPlayed,
      genres: genres ?? this.genres,
      rating: rating ?? this.rating,
      hltbMain: hltbMain ?? this.hltbMain,
      hltbCompletionist: hltbCompletionist ?? this.hltbCompletionist,
      summary: summary ?? this.summary,
      link: link ?? this.link,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      steamId: steamId ?? this.steamId,
      lastEditedTime: lastEditedTime,
    );
  }
}
