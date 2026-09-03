import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/game.dart';

void main() {
  group('Game Model SQLite & JSON Tests', () {
    test('toSqliteMap y fromSqliteMap preservan todos los campos fielmente', () {
      final initialDate = DateTime(2023, 11, 1);
      final updateDate = DateTime(2023, 12, 1);
      final game = Game(
        id: 'test-uuid-1234',
        title: 'Hades',
        coverUrl: 'https://ejemplo.com/hades.jpg',
        status: 'Jugado',
        platform: 'PC',
        hoursPlayed: 65.5,
        genres: ['Roguelike', 'Acción'],
        rating: '★★★★★',
        hltbMain: 22.5,
        hltbCompletionist: 97.0,
        summary: 'Juego sobresaliente de Supergiant Games',
        link: 'https://es.wikipedia.org/wiki/Hades',
        startDate: initialDate,
        completedDate: DateTime(2023, 12, 10),
        steamId: 1145360,
        createdAt: initialDate,
        updatedAt: updateDate,
      );

      final map = game.toSqliteMap();
      expect(map['id'], equals('test-uuid-1234'));
      expect(map['title'], equals('Hades'));
      expect(map['hours_played'], equals(65.5));
      expect(map['steam_id'], equals(1145360));
      expect(map['created_at'], equals(initialDate.toIso8601String()));
      expect(map['updated_at'], equals(updateDate.toIso8601String()));

      final restored = Game.fromSqliteMap(map);
      expect(restored.id, equals(game.id));
      expect(restored.title, equals(game.title));
      expect(restored.hoursPlayed, equals(game.hoursPlayed));
      expect(restored.genres, equals(game.genres));
      expect(restored.steamId, equals(game.steamId));
      expect(restored.status, equals('Jugado'));
      expect(restored.createdAt, equals(initialDate));
      expect(restored.updatedAt, equals(updateDate));
    });

    test('toJson y fromJson serializan y deserializan correctamente para respaldos', () {
      final game = Game(
        id: 'uuid-5678',
        title: 'Elden Ring',
        status: 'Jugando',
        hoursPlayed: 120.0,
        hltbMain: 58.0,
      );

      final json = game.toJson();
      final fromJson = Game.fromJson(json);

      expect(fromJson.title, equals('Elden Ring'));
      expect(fromJson.status, equals('Jugando'));
      expect(fromJson.hoursPlayed, equals(120.0));
      expect(fromJson.hltbMain, equals(58.0));
    });

    test('Límites defensivos de variables se aplican de forma transparente', () {
      final superLongTitle = 'A' * 300;
      final superLongSummary = 'B' * 3000;
      final superLongUrl = 'https://ejemplo.com/${'C' * 2500}';
      final rawGenres = List.generate(30, (i) => 'Género_${i}_${'D' * 60}');

      final game = Game(
        title: superLongTitle,
        summary: superLongSummary,
        coverUrl: superLongUrl,
        link: superLongUrl,
        genres: rawGenres,
        hoursPlayed: -15.5, // Negativo
        hltbMain: 150000.0, // Excesivo
      );

      expect(game.title.length, equals(255));
      expect(game.summary!.length, equals(2000));
      expect(game.coverUrl!.length, equals(2048));
      expect(game.link!.length, equals(2048));
      expect(game.genres.length, equals(20)); // Máximo 20 géneros
      expect(game.genres.first.length, equals(50)); // Máximo 50 caracteres
      expect(game.hoursPlayed, equals(0.0)); // Clamped a 0
      expect(game.hltbMain, equals(99999.0)); // Clamped a 99999
    });

    test('copyWith permite borrar campos asignando null explícito (patrón Sentinel)', () {
      final initialDate = DateTime(2023, 1, 1);
      final initialGame = Game(
        id: 'uuid-test',
        title: 'Hollow Knight',
        coverUrl: 'https://ejemplo.com/hollow.jpg',
        link: 'https://es.wikipedia.org/wiki/Hollow_Knight',
        rating: '★★★★★',
        hoursPlayed: 45.0,
        genres: ['Metroidvania', 'Indie'],
        hltbMain: 27.0,
        hltbCompletionist: 65.0,
        startDate: initialDate,
        completedDate: initialDate,
        steamId: 367520,
      );

      // Borrar enlace, portada, horas y géneros explícitamente pasando null
      final updated = initialGame.copyWith(
        link: null,
        coverUrl: null,
        hoursPlayed: null,
        genres: null,
        rating: null,
        hltbMain: null,
        hltbCompletionist: null,
        startDate: null,
        completedDate: null,
        steamId: null,
      );

      expect(updated.link, isNull);
      expect(updated.coverUrl, isNull);
      expect(updated.hoursPlayed, isNull);
      expect(updated.genres, isEmpty);
      expect(updated.rating, isNull);
      expect(updated.hltbMain, isNull);
      expect(updated.hltbCompletionist, isNull);
      expect(updated.startDate, isNull);
      expect(updated.completedDate, isNull);
      expect(updated.steamId, isNull);
      expect(updated.title, equals('Hollow Knight'));

      // Modificar título sin tocar link
      final updatedTitle = initialGame.copyWith(title: 'Silksong');
      expect(updatedTitle.title, equals('Silksong'));
      expect(updatedTitle.link, equals('https://es.wikipedia.org/wiki/Hollow_Knight'));
      expect(updatedTitle.hoursPlayed, equals(45.0));
      expect(updatedTitle.genres, equals(['Metroidvania', 'Indie']));
    });
  });
}
