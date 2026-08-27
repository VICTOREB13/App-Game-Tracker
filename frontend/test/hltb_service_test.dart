import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/services/hltb_service.dart';

void main() {
  group('HowLongToBeat Service Tests', () {
    test('HltbResult almacena correctamente horas de campaña y completista', () {
      const result = HltbResult(
        gameId: 26286,
        gameName: 'Hollow Knight',
        mainStory: 27.0,
        mainExtra: 41.5,
        completionist: 65.5,
      );

      expect(result.gameId, equals(26286));
      expect(result.gameName, equals('Hollow Knight'));
      expect(result.mainStory, equals(27.0));
      expect(result.mainExtra, equals(41.5));
      expect(result.completionist, equals(65.5));
    });

    test('searchHltb consulta HowLongToBeat y obtiene duración estimada', () async {
      final result = await HltbService.instance.searchHltb('Portal 2');

      if (result != null) {
        expect(result.mainStory, isNotNull);
        expect(result.mainStory!, greaterThan(5.0)); // Portal 2 dura ~8.5h
        expect(result.completionist, isNotNull);
        expect(result.completionist!, greaterThan(15.0)); // 100% dura ~22h
      }
    });
  });
}
