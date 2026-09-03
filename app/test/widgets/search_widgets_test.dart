import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tracker_app/models/game_details_result.dart';
import 'package:tracker_app/views/widgets/search/game_details_prompt_dialog.dart';
import 'package:tracker_app/views/widgets/search/prompt_dialog_header.dart';
import 'package:tracker_app/views/widgets/search/prompt_genre_selector.dart';
import 'package:tracker_app/views/widgets/search/prompt_platform_selector.dart';
import 'package:tracker_app/views/widgets/search/search_bar_input.dart';
import 'package:tracker_app/views/widgets/search/search_empty_state.dart';
import 'package:tracker_app/views/widgets/search/search_result_card.dart';

void main() {
  group('Search Widgets Suite', () {
    test('GameDetailsResult inicializa campos inmutables correctamente', () {
      const res = GameDetailsResult(
        status: 'Jugando',
        platform: 'PC',
        startDate: null,
        hoursPlayed: 14.5,
        genres: ['Action', 'RPG'],
      );

      expect(res.status, equals('Jugando'));
      expect(res.platform, equals('PC'));
      expect(res.startDate, isNull);
      expect(res.hoursPlayed, equals(14.5));
      expect(res.genres, equals(['Action', 'RPG']));
    });

    testWidgets('SearchBarInput responde a onSubmitted y onClear',
        (WidgetTester tester) async {
      final ctrl = TextEditingController(text: 'Elden');
      String? submittedQuery;
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarInput(
              controller: ctrl,
              onSubmitted: (q) => submittedQuery = q,
              onClear: () => clearCalled = true,
              isSearching: false,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Elden'), findsOneWidget);

      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedQuery, equals('Elden'));

      await tester.tap(find.byIcon(Icons.clear));
      expect(clearCalled, isTrue);
    });

    testWidgets('SearchBarInput muestra spinner cuando isSearching es true',
        (WidgetTester tester) async {
      final ctrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarInput(
              controller: ctrl,
              onSubmitted: (_) {},
              onClear: () {},
              isSearching: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('SearchEmptyState renderiza mensaje e icono representativo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(message: 'Busca tu juego favorito'),
          ),
        ),
      );

      expect(find.text('Busca tu juego favorito'), findsOneWidget);
      expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
    });

    testWidgets('SearchResultCard renderiza datos y responde a tap',
        (WidgetTester tester) async {
      bool tapped = false;
      final gameMap = {
        'name': 'Hollow Knight',
        'released': '2017-02-24',
        'genres': [
          {'name': 'Metroidvania'},
          {'name': 'Platformer'},
        ],
        'background_image': null,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultCard(
              rawgGame: gameMap,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Hollow Knight'), findsOneWidget);
      expect(find.text('2017-02-24'), findsOneWidget);
      expect(find.text('Metroidvania • Platformer'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      await tester.tap(find.byType(SearchResultCard));
      expect(tapped, isTrue);
    });

    testWidgets('PromptDialogHeader renderiza titulo, fecha y badge HLTB',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PromptDialogHeader(
              title: 'Celeste',
              releaseDate: '2018-01-25',
              playtime: 12,
            ),
          ),
        ),
      );

      expect(find.text('Celeste'), findsOneWidget);
      expect(find.text('Lanzamiento: 2018-01-25'), findsOneWidget);
      expect(find.text('HLTB estimado: 12h'), findsOneWidget);
    });

    testWidgets('PromptDialogHeader maneja fecha y HLTB nulos',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PromptDialogHeader(
              title: 'Indie Desconocido',
            ),
          ),
        ),
      );

      expect(find.text('Indie Desconocido'), findsOneWidget);
      expect(find.text('Sin fecha de lanzamiento'), findsOneWidget);
      expect(find.textContaining('HLTB estimado'), findsNothing);
    });

    testWidgets(
        'PromptPlatformSelector conmuta plataformas y responde a seleccion',
        (WidgetTester tester) async {
      String selected = 'PC';
      final detected = ['PC', 'PlayStation 5'];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: PromptPlatformSelector(
                selectedPlatform: selected,
                detectedPlatforms: detected,
                onPlatformChanged: (p) => setState(() => selected = p),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 recomendadas'), findsOneWidget);
      expect(find.text('+ Otras plataformas'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('Playstation 5'), findsOneWidget);
      expect(find.text('Nintendo Switch'), findsNothing);

      // Expandir otras plataformas
      await tester.tap(find.text('+ Otras plataformas'));
      await tester.pumpAndSettle();

      expect(find.text('Solo recomendadas'), findsOneWidget);
      expect(find.text('Nintendo Switch'), findsOneWidget);

      // Seleccionar Playstation 5
      await tester.tap(find.text('Playstation 5'));
      await tester.pumpAndSettle();
      expect(selected, equals('Playstation 5'));
    });

    testWidgets(
        'PromptGenreSelector expande acordeon y responde a cambio de genero',
        (WidgetTester tester) async {
      final selectedGenres = <String>['Action'];
      final available = ['Action', 'RPG', 'Shooter'];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: PromptGenreSelector(
                selectedGenres: selectedGenres,
                availableGenres: available,
                onGenreToggled: (g, sel) {
                  setState(() {
                    if (sel) {
                      selectedGenres.add(g);
                    } else {
                      selectedGenres.remove(g);
                    }
                  });
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Géneros'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);

      // Expandir acordeón
      await tester.tap(find.text('Géneros'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(3));

      // Desmarcar 'Action'
      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();
      expect(selectedGenres.contains('Action'), isFalse);
    });

    testWidgets(
        'GameDetailsPromptDialog renderiza cabecera, controles y botones',
        (WidgetTester tester) async {
      final gameMap = {
        'name': 'Hades',
        'released': '2020-09-17',
        'playtime': 25,
        'platforms': [
          {
            'platform': {'name': 'PC'}
          },
          {
            'platform': {'name': 'Nintendo Switch'}
          },
        ],
        'genres': [
          {'name': 'Roguelike'},
          {'name': 'Action'},
        ],
        'background_image': null,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDetailsPromptDialog(rawgGame: gameMap),
          ),
        ),
      );

      expect(find.text('Hades'), findsOneWidget);
      expect(find.text('Lanzamiento: 2020-09-17'), findsOneWidget);
      expect(find.text('HLTB estimado: 25h'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Horas Jugadas'), findsOneWidget);
      expect(find.text('Fecha de Inicio'), findsOneWidget);
      expect(find.text('Plataforma'), findsOneWidget);
      expect(find.text('2 recomendadas'), findsOneWidget);
      expect(find.text('Géneros'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Añadir a mi Biblioteca'), findsOneWidget);
    });
  });
}
