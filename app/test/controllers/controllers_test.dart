import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tracker_app/controllers/controllers.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DatabaseService dbService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'preferred_library_view_mode': true,
      'preferred_library_page_size': 2,
      'preferred_library_card_size': 200.0,
      'annual_game_goal_2026': 10,
    });

    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE games (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              cover_url TEXT,
              status TEXT NOT NULL DEFAULT 'Por jugar',
              platform TEXT,
              hours_played REAL DEFAULT 0.0,
              genres TEXT,
              rating TEXT,
              hltb_main REAL,
              hltb_completionist REAL,
              summary TEXT,
              link TEXT,
              start_date TEXT,
              completed_date TEXT,
              steam_id INTEGER,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    dbService = DatabaseService.instance;
    dbService.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardController Tests', () {
    test('Inicialización, paginación, filtros y quick actions funcionan correctamente', () async {
      final controller = DashboardController(dbService: dbService);

      final game1 = Game(
        id: '1',
        title: 'Cyberpunk 2077',
        status: 'Jugando',
        platform: 'PC',
        hoursPlayed: 45.0,
        genres: ['RPG', 'Acción'],
        hltbMain: 60.0,
      );
      final game2 = Game(
        id: '2',
        title: 'Bloodborne',
        status: 'Jugado',
        platform: 'PlayStation 4',
        hoursPlayed: 35.0,
        genres: ['Soulslike', 'Acción'],
        hltbMain: 30.0,
      );
      final game3 = Game(
        id: '3',
        title: 'Zelda: Tears of the Kingdom',
        status: 'Por jugar',
        platform: 'Nintendo Switch',
        hoursPlayed: 0.0,
        genres: ['Aventura'],
        hltbMain: 50.0,
      );

      await dbService.batchUpsertGames([game1, game2, game3]);

      await controller.initialize();

      expect(controller.totalGamesCount, equals(3));
      expect(controller.filteredGamesCount, equals(3));
      expect(controller.heroGame?.id, equals('1'));
      expect(controller.pageSize, equals(2));
      expect(controller.totalPages, equals(2));
      expect(controller.paginatedGames.length, equals(2));

      // Paginación
      controller.setPage(2);
      expect(controller.currentPage, equals(2));
      expect(controller.paginatedGames.length, equals(1));

      // Filtros
      await controller.setStatusFilter('Jugado');
      expect(controller.filteredGamesCount, equals(1));
      expect(controller.filteredGames.first.title, equals('Bloodborne'));
      expect(controller.activeFiltersCount, equals(1));

      // Quick add hours
      await controller.clearFilters();
      expect(controller.filteredGamesCount, equals(3));
      final updatedHero = await controller.quickAddHours(game1, 2.5);
      expect(updatedHero.hoursPlayed, equals(47.5));

      // View mode & zoom
      await controller.toggleViewMode();
      expect(controller.isGridView, isFalse);
      await controller.setGridCardExtent(300.0);
      expect(controller.gridCardExtent, equals(300.0));
    });
  });

  group('GameDetailController Tests', () {
    test('Control de ciclo de vida, edición, progresión de horas y guardado', () async {
      final initialGame = Game(
        id: 'test-detail-1',
        title: 'Metroid Prime Remastered',
        status: 'Por jugar',
        platform: 'Nintendo Switch',
        hoursPlayed: 0.0,
        genres: ['Acción'],
        hltbMain: 14.0,
      );
      await dbService.insertGame(initialGame);

      final controller = GameDetailController(
        game: initialGame,
        dbService: dbService,
      );

      expect(controller.title, equals('Metroid Prime Remastered'));
      expect(controller.status, equals('Por jugar'));

      // Modificación de campos
      controller.setTitle('Metroid Prime');
      controller.setPlatform('Nintendo Switch');
      controller.setRating('★★★★★');
      controller.toggleGenre('Aventura');

      expect(controller.genres, contains('Aventura'));

      // Progresión de horas: sumar 1.5 horas debe mover de 'Por jugar' a 'Jugando'
      controller.addHours(1.5);
      expect(controller.hoursPlayed, equals(1.5));
      expect(controller.status, equals('Jugando'));
      expect(controller.startDate, isNotNull);

      // Guardado en BD
      final saved = await controller.saveGame();
      expect(saved.title, equals('Metroid Prime'));
      expect(saved.status, equals('Jugando'));

      final fromDb = await dbService.getGameById('test-detail-1');
      expect(fromDb, isNotNull);
      expect(fromDb!.title, equals('Metroid Prime'));

      // Exportación de datos de ficha social
      final socialData = controller.exportSocialCardData();
      expect(socialData['title'], equals('Metroid Prime'));
      expect(socialData['hoursPlayed'], equals(1.5));
      expect(socialData['rating'], equals('★★★★★'));

      // Eliminación
      await controller.deleteGame();
      final deleted = await dbService.getGameById('test-detail-1');
      expect(deleted, isNull);
    });
  });

  group('GameSearchController Tests', () {
    test('Gestión de búsqueda, estado y guardado de juego nuevo', () async {
      final controller = GameSearchController(
        dbService: dbService,
      );

      expect(controller.isSearching, isFalse);
      expect(controller.results, isEmpty);

      // Ingesta de juego simulando respuesta de RAWG
      final rawgGame = {
        'name': 'Hollow Knight: Silksong',
        'background_image': 'https://media.rawg.io/media/games/silksong.jpg',
        'playtime': 25,
      };

      final newGame = await controller.addGameToLibrary(
        rawgGame: rawgGame,
        params: const AddGameParams(
          status: 'Por jugar',
          platform: 'PC',
          hoursPlayed: 0.0,
          genres: ['Metroidvania', 'Acción'],
        ),
      );

      expect(newGame.title, equals('Hollow Knight: Silksong'));
      expect(newGame.genres, contains('Metroidvania'));

      final fromDb = await dbService.getGameById(newGame.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.title, equals('Hollow Knight: Silksong'));
    });
  });

  group('SettingsController Tests', () {
    test('Operaciones de configuración y mantenimiento de base de datos', () async {
      final controller = SettingsController(
        dbService: dbService,
      );

      final testGame = Game(
        id: 'settings-game-1',
        title: 'Dark Souls III',
        status: 'Jugado',
        hoursPlayed: 80.0,
      );
      await dbService.insertGame(testGame);

      await controller.loadSettings();
      expect(controller.gameCount, equals(1));
      expect(controller.totalHours, equals(80.0));

      // Optimización VACUUM
      await controller.optimizeDatabase();
      expect(controller.errorMessage, isNull);

      // Limpieza de todos los juegos
      await controller.clearAllGames();
      expect(controller.gameCount, equals(0));
      expect(controller.totalHours, equals(0.0));
    });
  });

  group('AnalyticsController Tests', () {
    test('Cálculo exhaustivo de métricas, distribuciones, metas y Salón de la Fama', () async {
      final controller = AnalyticsController(
        dbService: dbService,
        initialYear: 2026,
      );

      final g1 = Game(
        id: 'a1',
        title: 'The Witcher 3',
        status: 'Jugado',
        platform: 'PC',
        hoursPlayed: 150.0,
        genres: ['RPG', 'Aventura'],
        rating: '★★★★★',
        hltbMain: 50.0,
        completedDate: DateTime(2026, 3, 15),
      );
      final g2 = Game(
        id: 'a2',
        title: 'Super Mario Odyssey',
        status: 'Jugado',
        platform: 'Nintendo Switch',
        hoursPlayed: 15.0,
        genres: ['Plataformas'],
        rating: '★★★★★',
        hltbMain: 12.0,
        completedDate: DateTime(2026, 4, 10),
      );
      final g3 = Game(
        id: 'a3',
        title: 'Portal',
        status: 'Jugado',
        platform: 'PC',
        hoursPlayed: 3.5,
        genres: ['Puzles'],
        rating: '★★★★✰',
        hltbMain: 3.0,
        completedDate: DateTime(2025, 8, 20), // Otro año
      );
      final g4 = Game(
        id: 'a4',
        title: 'Final Fantasy VII Rebirth',
        status: 'Jugando',
        platform: 'PlayStation 5',
        hoursPlayed: 40.0,
        genres: ['RPG'],
        hltbMain: 70.0,
      );
      final g5 = Game(
        id: 'a5',
        title: 'Chrono Trigger',
        status: 'Por jugar',
        platform: 'PC',
        hoursPlayed: 0.0,
        genres: ['RPG'],
        hltbMain: 25.0,
      );

      await dbService.batchUpsertGames([g1, g2, g3, g4, g5]);

      await controller.loadAnalytics();

      // Métricas generales
      expect(controller.totalGames, equals(5));
      expect(controller.totalHours, equals(208.5));
      expect(controller.completedCount, equals(3));
      expect(controller.playingCount, equals(1));
      expect(controller.backlogCount, equals(1));
      expect(controller.completionRate, equals('60.0'));

      // Distribución por estado
      final statusDist = controller.statusDistribution;
      expect(statusDist['Jugado'], equals(3));
      expect(statusDist['Jugando'], equals(1));
      expect(statusDist['Por jugar'], equals(1));

      // Distribución por plataforma
      final platTotals = controller.platformTotals;
      expect(platTotals['PC'], equals(3));
      expect(platTotals['Nintendo Switch'], equals(1));
      expect(platTotals['PlayStation 5'], equals(1));

      // Calculadora de Backlog
      expect(controller.backlogGames.length, equals(1));
      expect(controller.totalBacklogHours, equals(25.0));

      // Metas Anuales 2026
      expect(controller.selectedYear, equals(2026));
      expect(controller.annualGoal, equals(10));
      expect(controller.completedInSelectedYearCount, equals(2)); // g1 y g2
      expect(controller.yearProgress, closeTo(0.2, 0.001));
      expect(controller.isYearGoalMet, isFalse);
      expect(controller.remainingForYearGoal, equals(8));

      // Cambio de meta
      await controller.setAnnualGoal(2);
      expect(controller.annualGoal, equals(2));
      expect(controller.isYearGoalMet, isTrue);

      // Salón de la Fama
      expect(controller.titanGame?.title, equals('The Witcher 3')); // 150h
      expect(controller.masterpieceGame?.title, equals('The Witcher 3')); // 5 estrellas con más horas
      expect(controller.agileGame?.title, equals('Portal')); // 3.5h completado

      // Top rated games
      final topRated = controller.topRatedGames;
      expect(topRated.length, equals(3));
      expect(topRated.first.rating, equals('★★★★★'));
    });
  });
}
