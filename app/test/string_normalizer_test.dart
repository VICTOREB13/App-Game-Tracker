import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/services/string_normalizer.dart';

void main() {
  group('StringNormalizer Tests (Replicación de games.py)', () {
    test('cleanTitle purga símbolos registrados, marcas y puntuación', () {
      expect(
        StringNormalizer.cleanTitle('Elden Ring™'),
        equals('elden ring'),
      );
      expect(
        StringNormalizer.cleanTitle('Cyberpunk 2077®: Phantom Liberty'),
        equals('cyberpunk 2077 phantom liberty'),
      );
      expect(
        StringNormalizer.cleanTitle('Resident Evil 4 (2023) - Remake!'),
        equals('resident evil 4 2023 remake'),
      );
    });

    test('similarity detecta coincidencias mayores a 0.90 con ligeras variaciones', () {
      final sim1 = StringNormalizer.similarity(
        'Hollow Knight',
        'Hollow Knight™',
      );
      expect(sim1, greaterThanOrEqualTo(0.90));

      final sim2 = StringNormalizer.similarity(
        'God of War Ragnarök',
        'God of War Ragnarok',
      );
      expect(sim2, greaterThanOrEqualTo(0.90));

      final sim3 = StringNormalizer.similarity(
        'Elden Ring',
        'Dark Souls III',
      );
      expect(sim3, lessThan(0.60));
    });

    test('cleanTitle maneja cadenas nulas o vacías de forma segura', () {
      expect(StringNormalizer.cleanTitle(null), equals(''));
      expect(StringNormalizer.cleanTitle('   '), equals(''));
      expect(StringNormalizer.similarity(null, null), equals(1.0));
      expect(StringNormalizer.similarity('', 'Game'), equals(0.0));
    });

    test('sanitizeFilename genera nombres seguros para sistemas de archivos', () {
      expect(
        StringNormalizer.sanitizeFilename('The Witcher 3: Wild Hunt™'),
        equals('The_Witcher_3_Wild_Hunt'),
      );
      expect(
        StringNormalizer.sanitizeFilename('  ¿Juego / Test: Vol. 1?  '),
        equals('Juego__Test_Vol_1'),
      );
      expect(StringNormalizer.sanitizeFilename(''), equals('archivo'));
    });

    test('cleanSpecialCharacters remueve marcas registradas preservando casing', () {
      expect(
        StringNormalizer.cleanSpecialCharacters('Pokémon™ Scarlet® & Violet©'),
        equals('Pokémon Scarlet & Violet'),
      );
    });
  });
}
