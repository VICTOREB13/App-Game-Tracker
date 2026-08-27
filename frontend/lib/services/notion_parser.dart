/// Utility functions to parse Notion API property objects into Dart types
/// and to build Notion property objects from Dart values.

class NotionParser {
  // ─── PARSERS (Notion → Dart) ───

  /// Parse a title property → String
  static String parseTitle(Map<String, dynamic>? property) {
    if (property == null) return 'Sin título';
    final titleList = property['title'] as List?;
    if (titleList == null || titleList.isEmpty) return 'Sin título';
    return titleList.map((t) => t['plain_text'] ?? '').join('');
  }

  /// Parse a status property → String
  static String parseStatus(Map<String, dynamic>? property) {
    if (property == null) return 'Por jugar';
    final status = property['status'];
    if (status == null) return 'Por jugar';
    return status['name'] ?? 'Por jugar';
  }

  /// Parse a select property → String?
  static String? parseSelect(Map<String, dynamic>? property) {
    if (property == null) return null;
    final select = property['select'];
    if (select == null) return null;
    return select['name'];
  }

  /// Parse a multi_select property → List<String>
  static List<String> parseMultiSelect(Map<String, dynamic>? property) {
    if (property == null) return [];
    final multiSelect = property['multi_select'] as List?;
    if (multiSelect == null) return [];
    return multiSelect.map((item) => item['name'] as String).toList();
  }

  /// Parse a number property → num?
  static num? parseNumber(Map<String, dynamic>? property) {
    if (property == null) return null;
    return property['number'];
  }

  /// Parse a date property → DateTime?
  static DateTime? parseDate(Map<String, dynamic>? property) {
    if (property == null) return null;
    final date = property['date'];
    if (date == null) return null;
    final start = date['start'];
    if (start == null) return null;
    return DateTime.tryParse(start);
  }

  /// Parse a files property → String? (first file URL)
  static String? parseFiles(Map<String, dynamic>? property) {
    if (property == null) return null;
    final files = property['files'] as List?;
    if (files == null || files.isEmpty) return null;
    final file = files[0];
    // Notion files can be "file" type (hosted by Notion) or "external"
    if (file['type'] == 'file') {
      return file['file']?['url'];
    } else if (file['type'] == 'external') {
      return file['external']?['url'];
    }
    return null;
  }

  /// Parse a rich_text property → String?
  static String? parseRichText(Map<String, dynamic>? property) {
    if (property == null) return null;
    final richText = property['rich_text'] as List?;
    if (richText == null || richText.isEmpty) return null;
    return richText.map((t) => t['plain_text'] ?? '').join('');
  }

  /// Parse a url property → String?
  static String? parseUrl(Map<String, dynamic>? property) {
    if (property == null) return null;
    return property['url'];
  }

  /// Parse a formula property → dynamic
  static dynamic parseFormula(Map<String, dynamic>? property) {
    if (property == null) return null;
    final formula = property['formula'];
    if (formula == null) return null;
    final type = formula['type'];
    return formula[type];
  }

  // ─── BUILDERS (Dart → Notion) ───

  /// Build a title property
  static Map<String, dynamic> buildTitle(String value) {
    return {
      'title': [
        {
          'type': 'text',
          'text': {'content': value},
        }
      ],
    };
  }

  /// Build a status property
  static Map<String, dynamic> buildStatus(String name) {
    return {
      'status': {'name': name},
    };
  }

  /// Build a select property
  static Map<String, dynamic> buildSelect(String? name) {
    if (name == null || name.trim().isEmpty) {
      return {'select': null};
    }
    return {
      'select': {'name': name.trim()},
    };
  }

  /// Build a multi_select property
  static Map<String, dynamic> buildMultiSelect(List<String> names) {
    return {
      'multi_select': names
          .where((n) => n.trim().isNotEmpty)
          .map((n) => {'name': n.trim()})
          .toList(),
    };
  }

  /// Build a number property
  static Map<String, dynamic> buildNumber(num? value) {
    return {
      'number': value,
    };
  }

  /// Build a date property
  static Map<String, dynamic> buildDate(DateTime? date) {
    if (date == null) {
      return {'date': null};
    }
    return {
      'date': {
        'start': date.toIso8601String().split('T')[0],
      },
    };
  }

  /// Build a rich_text property
  static Map<String, dynamic> buildRichText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return {'rich_text': []};
    }
    return {
      'rich_text': [
        {
          'type': 'text',
          'text': {'content': value.trim()},
        }
      ],
    };
  }

  /// Build a url property
  static Map<String, dynamic> buildUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return {'url': null};
    }
    return {
      'url': value.trim(),
    };
  }

  /// Build an external files property (for cover images)
  static Map<String, dynamic> buildExternalFile(String? url) {
    if (url == null || url.trim().isEmpty) {
      return {'files': []};
    }
    final cleanUrl = url.trim();
    // Notion API rejects hosted file URLs (AWS S3) if sent as 'external'
    if (cleanUrl.contains('amazonaws.com') ||
        cleanUrl.contains('prod-files-secure') ||
        cleanUrl.contains('notion-static.com')) {
      return {'files': []};
    }
    return {
      'files': [
        {
          'type': 'external',
          'name': 'cover',
          'external': {'url': cleanUrl},
        }
      ],
    };
  }
}
