import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/game.dart';

void main() {
  group('Game.applyPlaytimeProgress Unit Tests', () {
    test('additionalHours incrementa hoursPlayed correctamente', () {
      final game = Game(
        title: 'Celeste',
        status: 'Jugando',
        hoursPlayed: 5.0,
      );

      final progressed = game.applyPlaytimeProgress(additionalHours: 2.5);
      expect(progressed.hoursPlayed, equals(7.5));
      expect(game.hoursPlayed, equals(5.0)); // Inmutabilidad garantizada
    });

    test('totalHours sobreescribe el total acumulado', () {
      final game = Game(
        title: 'Celeste',
        status: 'Jugando',
        hoursPlayed: 5.0,
      );

      final progressed = game.applyPlaytimeProgress(totalHours: 12.0);
      expect(progressed.hoursPlayed, equals(12.0));
    });

    test('Transición automática a Jugado al superar hltbMain', () {
      final initialDate = DateTime(2023, 1, 1);
      final game = Game(
        title: 'Portal',
        status: 'Jugando',
        hoursPlayed: 2.0,
        hltbMain: 3.5,
        startDate: initialDate,
      );

      final progressed = game.applyPlaytimeProgress(additionalHours: 2.0); // 4.0 >= 3.5
      expect(progressed.hoursPlayed, equals(4.0));
      expect(progressed.status, equals('Jugado'));
      expect(progressed.completedDate, isNotNull);
      expect(progressed.startDate, equals(initialDate));
    });

    test('Preserva completedDate existente si ya estaba como Jugado', () {
      final completed = DateTime(2023, 5, 20);
      final game = Game(
        title: 'Portal 2',
        status: 'Jugado',
        hoursPlayed: 10.0,
        hltbMain: 8.5,
        completedDate: completed,
      );

      final progressed = game.applyPlaytimeProgress(additionalHours: 1.0);
      expect(progressed.status, equals('Jugado'));
      expect(progressed.completedDate, equals(completed));
    });

    test('Transición automática a Jugando al alcanzar >= 1.0h partiendo de Por jugar', () {
      final game = Game(
        title: 'Sekiro',
        status: 'Por jugar',
        hoursPlayed: 0.0,
        hltbMain: 30.0,
      );

      final progressed = game.applyPlaytimeProgress(additionalHours: 1.5);
      expect(progressed.hoursPlayed, equals(1.5));
      expect(progressed.status, equals('Jugando'));
      expect(progressed.startDate, isNotNull);
      expect(progressed.completedDate, isNull);
    });

    test('No transiciona a Jugando si horas < 1.0h partiendo de Por jugar', () {
      final game = Game(
        title: 'Elden Ring',
        status: 'Por jugar',
        hoursPlayed: 0.0,
        hltbMain: 60.0,
      );

      final progressed = game.applyPlaytimeProgress(additionalHours: 0.5);
      expect(progressed.hoursPlayed, equals(0.5));
      expect(progressed.status, equals('Por jugar'));
      expect(progressed.startDate, isNull);
    });
  });
}
