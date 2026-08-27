import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/services/metadata_service.dart';

void main() {
  group('MetadataService Tests', () {
    test('searchWikipedia encuentra enlaces válidos para títulos canónicos', () async {
      final wikiUrl1 = await MetadataService.instance.searchWikipedia('Hollow Knight');
      expect(wikiUrl1, isNotNull);
      expect(wikiUrl1, contains('wikipedia.org/wiki/'));
      expect(wikiUrl1, contains('Hollow_Knight'));

      final wikiUrl2 = await MetadataService.instance.searchWikipedia('Elden Ring™');
      expect(wikiUrl2, isNotNull);
      expect(wikiUrl2, contains('wikipedia.org/wiki/'));
      expect(wikiUrl2, contains('Elden_Ring'));
    });
  });
}
