import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/views/widgets/dashboard/dashboard_fab.dart';
import 'package:tracker_app/views/widgets/dashboard/dashboard_filter_bar.dart';
import 'package:tracker_app/views/widgets/dashboard/dashboard_skeleton_grid.dart';
import 'package:tracker_app/views/widgets/dashboard/dashboard_view_header.dart';
import 'package:tracker_app/views/widgets/dashboard/game_card_grid.dart';
import 'package:tracker_app/views/widgets/dashboard/game_card_list.dart';
import 'package:tracker_app/views/widgets/dashboard/hero_spotlight_card.dart';
import 'package:tracker_app/views/widgets/dashboard/pagination_control_bar.dart';
import 'package:tracker_app/views/widgets/filter_modal_sheet.dart';

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

    testWidgets('DashboardSkeletonGrid renderiza la cantidad solicitada de placeholders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeletonGrid(cardExtent: 200, itemCount: 6),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('DashboardViewHeader renderiza contadores y responde a toggle de vista',
        (WidgetTester tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardViewHeader(
              filteredGamesCount: 15,
              totalGamesCount: 40,
              searchQuery: 'Zelda',
              isGridView: true,
              gridCardExtent: 220,
              onToggleViewMode: () => toggleCalled = true,
              onGridCardExtentChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('15 de 40 juegos'), findsOneWidget);
      expect(find.text('Filtro: "Zelda"'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('Lista'), findsOneWidget);

      await tester.tap(find.text('Lista'));
      expect(toggleCalled, isTrue);
    });

    testWidgets('DashboardFilterBar renderiza chips de estado y botón de limpiar',
        (WidgetTester tester) async {
      String? selectedStatus;
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardFilterBar(
              selectedStatus: 'Jugando',
              selectedPlatform: 'Todas',
              selectedGenre: 'Todos',
              selectedSort: 'Recientes',
              platformOptions: const [
                FilterOption(label: 'PC', count: 10),
              ],
              genreOptions: const [
                FilterOption(label: 'RPG', count: 5),
              ],
              activeFiltersCount: 1,
              onStatusSelected: (s) => selectedStatus = s,
              onPlatformSelected: (_) {},
              onGenreSelected: (_) {},
              onSortSelected: (_) {},
              onClearFilters: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('Jugando'), findsWidgets);
      expect(find.text('Limpiar'), findsOneWidget);

      await tester.tap(find.text('Limpiar'));
      expect(cleared, isTrue);

      await tester.tap(find.text('Por jugar'));
      expect(selectedStatus, equals('Por jugar'));
    });

    testWidgets('DashboardFab renderiza versión extendida en desktop y simple en móvil',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardFab(
              isMobile: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Añadir'), findsOneWidget);
      await tester.tap(find.text('Añadir'));
      expect(pressed, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardFab(
              isMobile: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('PaginationControlBar renderiza botón integrado onAddGame',
        (WidgetTester tester) async {
      bool addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationControlBar(
              totalItems: 10,
              currentPage: 1,
              pageSize: 25,
              totalPages: 1,
              onPageChanged: (_) {},
              onPageSizeChanged: (_) {},
              onAddGame: () => addCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Añadir juego'), findsOneWidget);
      await tester.tap(find.text('Añadir juego'));
      expect(addCalled, isTrue);
    });
  });
}
