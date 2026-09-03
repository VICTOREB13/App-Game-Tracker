import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/views/widgets/platform_helper.dart';

void main() {
  group('PlatformHelper Unit Tests', () {
    test('allPlatforms contiene las 15 plataformas estándar', () {
      expect(PlatformHelper.allPlatforms.length, equals(15));
      expect(PlatformHelper.allPlatforms, contains('PC'));
      expect(PlatformHelper.allPlatforms, contains('Playstation 5'));
      expect(PlatformHelper.allPlatforms, contains('Nintendo Switch'));
      expect(PlatformHelper.allPlatforms, contains('Xbox'));
    });

    test('canonicalize normaliza variantes a sus nombres canónicos', () {
      expect(PlatformHelper.canonicalize('steam'), equals('PC'));
      expect(PlatformHelper.canonicalize('windows'), equals('PC'));
      expect(PlatformHelper.canonicalize('ps5'), equals('Playstation 5'));
      expect(PlatformHelper.canonicalize('playstation 5'), equals('Playstation 5'));
      expect(PlatformHelper.canonicalize('ps4'), equals('Playstation 4'));
      expect(PlatformHelper.canonicalize('xbox series x'), equals('Xbox'));
      expect(PlatformHelper.canonicalize('switch'), equals('Nintendo Switch'));
      expect(PlatformHelper.canonicalize('macos'), equals('Mac'));
      expect(PlatformHelper.canonicalize('android'), equals('Mobile'));
      expect(PlatformHelper.canonicalize('Plataforma Rara'), equals('Plataforma Rara'));
    });

    test('getOrderedPlatforms sin parámetros retorna el catálogo completo estándar', () {
      final platforms = PlatformHelper.getOrderedPlatforms();
      expect(platforms, equals(PlatformHelper.allPlatforms));
      expect(platforms.length, equals(PlatformHelper.allPlatforms.length));
    });

    test('getOrderedPlatforms con currentPlatform prioriza la plataforma actual en el índice 0', () {
      final platforms = PlatformHelper.getOrderedPlatforms(currentPlatform: 'ps5');
      expect(platforms.first, equals('Playstation 5'));
      // No debe haber duplicados de Playstation 5
      expect(platforms.where((p) => p == 'Playstation 5').length, equals(1));
      // Debe contener todas las demás de allPlatforms
      for (final std in PlatformHelper.allPlatforms) {
        expect(platforms, contains(std));
      }
    });

    test('getOrderedPlatforms con recommended coloca las recomendadas primero y deduplica', () {
      final platforms = PlatformHelper.getOrderedPlatforms(
        recommended: ['Steam', 'Nintendo Switch', 'ps5'],
      );

      expect(platforms[0], equals('PC'));
      expect(platforms[1], equals('Nintendo Switch'));
      expect(platforms[2], equals('Playstation 5'));

      // Verifica unicidad total
      final uniqueSet = platforms.toSet();
      expect(uniqueSet.length, equals(platforms.length));
      expect(platforms.length, equals(PlatformHelper.allPlatforms.length));
    });

    test('getOrderedPlatforms con currentPlatform y recommended combina sin duplicados', () {
      final platforms = PlatformHelper.getOrderedPlatforms(
        currentPlatform: 'Nintendo Switch',
        recommended: ['Steam', 'Switch', 'PS5'],
      );

      expect(platforms[0], equals('Nintendo Switch'));
      expect(platforms[1], equals('PC'));
      expect(platforms[2], equals('Playstation 5'));

      final uniqueSet = platforms.toSet();
      expect(uniqueSet.length, equals(platforms.length));
    });

    test('getOrderedPlatforms preserva plataformas no estándar personalizadas', () {
      final platforms = PlatformHelper.getOrderedPlatforms(
        currentPlatform: 'Sega Dreamcast',
        recommended: ['Game Boy Color'],
      );

      expect(platforms[0], equals('Sega Dreamcast'));
      expect(platforms[1], equals('Game Boy Color'));
      expect(platforms, contains('PC'));
      expect(platforms.length, equals(PlatformHelper.allPlatforms.length + 2));
    });

    test('getColor asigna colores distintivos según la marca de la consola', () {
      expect(PlatformHelper.getColor('Playstation 5'), equals(const Color(0xFF0070D1)));
      expect(PlatformHelper.getColor('Nintendo Switch'), equals(const Color(0xFFE60012)));
      expect(PlatformHelper.getColor('Xbox'), equals(const Color(0xFF107C10)));
      expect(PlatformHelper.getColor('PC'), equals(const Color(0xFF00F0FF)));
      expect(PlatformHelper.getColor('Mobile'), equals(const Color(0xFFFF2D78)));
      expect(PlatformHelper.getColor('Otra'), equals(const Color(0xFFFFBE0B)));
    });
  });

  group('PlatformHelper Widget Tests', () {
    testWidgets('buildBadge renderiza el texto y el icono de la plataforma', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => PlatformHelper.buildBadge('Nintendo Switch'),
            ),
          ),
        ),
      );

      expect(find.text('Nintendo Switch'), findsOneWidget);
    });
  });
}
