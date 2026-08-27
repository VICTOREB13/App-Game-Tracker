import 'dart:math';

/// Utilidades de normalización y comparación difusa de títulos de videojuegos
/// Port directo de la lógica implementada originalmente en `games.py`.
class StringNormalizer {
  /// Borra símbolos de marca y puntuación para una comparación justa.
  /// Reemplaza ['™', '®', '©', ':', '.', ',', '!', '?', '-', '_', '(', ')'] por espacios.
  static String cleanTitle(String? name) {
    if (name == null || name.trim().isEmpty) return '';

    String cleaned = name;
    const charsToRemove = [
      '™', '®', '©', ':', '.', ',', '!', '?', '-', '_', '(', ')'
    ];

    for (final char in charsToRemove) {
      cleaned = cleaned.replaceAll(char, ' ');
    }

    // Minúsculas, separación por espacios en blanco y unión limpia
    final words = cleaned.toLowerCase().split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty).join(' ').trim();
  }

  /// Calcula qué tan parecidos son dos nombres de juegos (rango de 0.0 a 1.0)
  /// Equivalente a SequenceMatcher.ratio() de Python.
  static double similarity(String? a, String? b) {
    final cleanA = cleanTitle(a);
    final cleanB = cleanTitle(b);

    if (cleanA.isEmpty && cleanB.isEmpty) return 1.0;
    if (cleanA.isEmpty || cleanB.isEmpty) return 0.0;
    if (cleanA == cleanB) return 1.0;

    // Cálculo de coeficiente de similitud basado en bigramas (Sørensen-Dice)
    // muy preciso para títulos de videojuegos con ligeras variaciones
    final bigramsA = _getBigrams(cleanA);
    final bigramsB = _getBigrams(cleanB);

    if (bigramsA.isEmpty || bigramsB.isEmpty) {
      return _levenshteinRatio(cleanA, cleanB);
    }

    int matches = 0;
    final bCopy = List<String>.from(bigramsB);

    for (final bigram in bigramsA) {
      final index = bCopy.indexOf(bigram);
      if (index != -1) {
        matches++;
        bCopy.removeAt(index);
      }
    }

    final dice = (2.0 * matches) / (bigramsA.length + bigramsB.length);

    // Complementamos con Levenshtein para mayor precisión en palabras cortas
    final lev = _levenshteinRatio(cleanA, cleanB);
    return max(dice, lev);
  }

  static List<String> _getBigrams(String str) {
    final bigrams = <String>[];
    for (int i = 0; i < str.length - 1; i++) {
      bigrams.add(str.substring(i, i + 2));
    }
    return bigrams;
  }

  static double _levenshteinRatio(String s, String t) {
    final m = s.length;
    final n = t.length;
    if (m == 0) return n == 0 ? 1.0 : 0.0;
    if (n == 0) return 0.0;

    final d = List.generate(m + 1, (i) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (int j = 1; j <= n; j++) {
      for (int i = 1; i <= m; i++) {
        final cost = (s[i - 1] == t[j - 1]) ? 0 : 1;
        d[i][j] = min(
          d[i - 1][j] + 1,
          min(d[i][j - 1] + 1, d[i - 1][j - 1] + cost),
        );
      }
    }

    final distance = d[m][n];
    return 1.0 - (distance.toDouble() / max(m, n));
  }
}
