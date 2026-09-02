import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/widgets/dashboard/game_card_grid.dart';
import 'package:tracker_app/widgets/dashboard/game_card_list.dart';
import 'package:tracker_app/widgets/dashboard/hero_spotlight_card.dart';
import 'package:tracker_app/widgets/dashboard/pagination_control_bar.dart';

void main() {
  final testGame = Game(
    id: 'test-game-1',
    title: 'Elden Ring',
    platform: 'PC',
    status: 'Jugando',
    hoursPlayed: 85.5,
    hltbMain: 60.0,
    rating: '★★★★★',
    genres: ['RPG', 'Acción'],
  );

  group('Dashboard Modular Widgets Tests', () {
    testWidgets('GameCardGrid renderiza título, plataforma, status y rating',
        (WidgetTester tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 320,
              child: GameCardGrid(
                game: testGame,
                onTap: () => tapped = true,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Elden Ring'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('Jugando'), findsOneWidget);
      expect(find.text('★★★★★'), findsOneWidget);

      await tester.tap(find.text('Elden Ring'));
      expect(tapped, isTrue);

      await tester.longPress(find.text('Elden Ring'));
      expect(longPressed, isTrue);
    });

    testWidgets('GameCardList renderiza fila compacta y responde a quick add hours',
        (WidgetTester tester) async {
      bool quickAdded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardList(
              game: testGame,
              onTap: () {},
              onLongPress: () {},
              onQuickAddHours: () => quickAdded = true,
            ),
          ),
        ),
      );

      expect(find.text('Elden Ring'), findsOneWidget);
      expect(find.text('+1h'), findsOneWidget);

      await tester.tap(find.text('+1h'));
      expect(quickAdded, isTrue);
    });

    testWidgets('HeroSpotlightCard renderiza badge JUGANDO AHORA con RepaintBoundary',
        (WidgetTester tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroSpotlightCard(
              game: testGame,
              pulseAnimation: controller,
              onTap: () {},
              onQuickAddHours: () {},
            ),
          ),
        ),
      );

      expect(find.text('JUGANDO AHORA'), findsOneWidget);
      expect(find.text('Elden Ring'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);

      controller.dispose();
    });

    testWidgets('PaginationControlBar cambia de página y tamaño de página',
        (WidgetTester tester) async {
      int? changedPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationControlBar(
              totalItems: 50,
              currentPage: 1,
              pageSize: 25,
              totalPages: 2,
              onPageChanged: (page) => changedPage = page,
              onPageSizeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byTooltip('Página siguiente'), findsOneWidget);

      await tester.tap(find.byTooltip('Página siguiente'));
      expect(changedPage, equals(2));
    });
  });
}
