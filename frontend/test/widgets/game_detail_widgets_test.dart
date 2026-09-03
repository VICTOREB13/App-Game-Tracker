import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/views/widgets/game_detail/game_detail_form_fields.dart';
import 'package:tracker_app/views/widgets/game_detail/game_detail_header.dart';
import 'package:tracker_app/views/widgets/game_detail/game_genre_selector.dart';
import 'package:tracker_app/views/widgets/game_detail/game_hltb_progress_card.dart';
import 'package:tracker_app/views/widgets/game_detail/social_card_preview.dart';

void main() {
  group('GameDetail Modular Widgets Tests', () {
    testWidgets('GameDetailHeader renderiza badge de plataforma y pill de estado',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GameDetailHeader(
                gameId: 'game-123',
                coverUrl: null,
                platform: 'Nintendo Switch',
                status: 'Jugando',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nintendo Switch'), findsOneWidget);
      expect(find.text('Jugando'), findsOneWidget);
    });

    testWidgets('GameHltbProgressCard calcula porcentaje y muestra horas faltantes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameHltbProgressCard(
              hoursPlayed: 30.0,
              hltbMain: 60.0,
              hltbCompletionist: 100.0,
            ),
          ),
        ),
      );

      expect(find.text('Progreso de Campaña'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Historia: 60h'), findsOneWidget);
      expect(find.text('100% Completista: 100h'), findsOneWidget);
      expect(find.text('Faltan ~30h'), findsOneWidget);
    });

    testWidgets('GameHltbProgressCard muestra Completado cuando supera el objetivo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameHltbProgressCard(
              hoursPlayed: 75.0,
              hltbMain: 60.0,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Completado'), findsOneWidget);
    });

    testWidgets('GameHltbProgressCard es SizedBox.shrink cuando hltbMain <= 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameHltbProgressCard(
              hoursPlayed: 10.0,
              hltbMain: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Progreso de Campaña'), findsNothing);
    });

    testWidgets('GameGenreSelector expande acordeón e interactúa con chips',
        (WidgetTester tester) async {
      List<String>? updatedGenres;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GameGenreSelector(
                selectedGenres: const ['RPG', 'Acción'],
                onGenresChanged: (genres) => updatedGenres = genres,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Seleccionar Géneros'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('RPG • Acción'), findsOneWidget);

      // Tap para desplegar el acordeón
      await tester.tap(find.text('Seleccionar Géneros'));
      await tester.pumpAndSettle();

      // Debe mostrar chips de géneros
      expect(find.byType(FilterChip), findsWidgets);

      // Tap en un chip para deseleccionarlo
      await tester.tap(find.text('RPG'));
      expect(updatedGenres, isNotNull);
      expect(updatedGenres!.contains('RPG'), isFalse);
    });

    testWidgets('GameDetailFormFields: QuickHourButton y GameHoursEditor responden a eventos',
        (WidgetTester tester) async {
      final controller = TextEditingController(text: '10');
      double added = 0;
      bool changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GameHoursEditor(
                controller: controller,
                onAddHours: (delta) => added += delta,
                onChanged: () => changed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Horas Jugadas'), findsOneWidget);
      expect(find.text('+30m'), findsOneWidget);
      expect(find.text('+1h'), findsOneWidget);
      expect(find.text('+2h'), findsOneWidget);

      await tester.tap(find.text('+1h'));
      expect(added, equals(1.0));

      await tester.tap(find.text('+30m'));
      expect(added, equals(1.5));

      await tester.enterText(find.byType(TextField), '15');
      expect(changed, isTrue);

      controller.dispose();
    });

    testWidgets('GameDetailFormFields: GameDatePickerField muestra fecha formateada',
        (WidgetTester tester) async {
      final date = DateTime(2026, 9, 2);
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDatePickerField(
              label: 'Fecha de Inicio',
              date: date,
              onTap: () {},
              onClear: () => clearCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Fecha de Inicio'), findsOneWidget);
      expect(find.text('02/09/2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(clearCalled, isTrue);
    });

    testWidgets('GameDetailFormFields: GameSaveButton muestra spinner cuando isSaving es true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameSaveButton(
              isSaving: true,
              onSave: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameSaveButton(
              isSaving: false,
              onSave: null,
            ),
          ),
        ),
      );

      expect(find.text('Guardar Cambios'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('SocialCardPreview renderiza información de reseña y marca AGT',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialCardPreview(
                title: 'Hollow Knight: Silksong',
                platform: 'PC',
                status: 'Jugado',
                hoursPlayed: 45,
                rating: '★★★★★',
                summary: 'Una obra maestra absoluta del género metroidvania.',
                coverUrl: null,
                completedDate: DateTime(2026, 8, 15),
                isDark: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hollow Knight: Silksong'), findsOneWidget);
      expect(find.text('AGT'), findsOneWidget);
      expect(find.text('45h jugadas'), findsOneWidget);
      expect(find.text('★★★★★'), findsOneWidget);
      expect(find.text('“Una obra maestra absoluta del género metroidvania.”'), findsOneWidget);
    });
  });
}
