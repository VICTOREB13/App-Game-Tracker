import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
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

          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_steam_id ON games(steam_id);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_platform ON games(platform);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_title ON games(title);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_title_nocase ON games(title COLLATE NOCASE);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_updated_at ON games(updated_at DESC);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_hours_played ON games(hours_played DESC);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_rating ON games(rating DESC, hours_played DESC);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_games_status_updated ON games(status, updated_at DESC);');
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('DatabaseService Tests', () {
    test('Condiciones de Carrera: 50 llamadas asíncronas simultáneas resuelven a la misma instancia', () async {
      final futures = List.generate(50, (_) => DatabaseService.instance.database);
      final results = await Future.wait(futures);

      for (final instance in results) {
        expect(identical(instance, results.first), isTrue);
        expect(instance.isOpen, isTrue);
      }
    });

    test('Pragmas de Integridad e Índices B-Tree están creados correctamente', () async {
      final foreignKeysRes = await db.rawQuery('PRAGMA foreign_keys;');
      expect(Sqflite.firstIntValue(foreignKeysRes), equals(1));

      final indexRes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='games';",
      );
      final indexNames = indexRes.map((r) => r['name']?.toString()).toSet();

      expect(indexNames, contains('idx_games_steam_id'));
      expect(indexNames, contains('idx_games_status'));
      expect(indexNames, contains('idx_games_platform'));
      expect(indexNames, contains('idx_games_title'));
      expect(indexNames, contains('idx_games_title_nocase'));
      expect(indexNames, contains('idx_games_updated_at'));
      expect(indexNames, contains('idx_games_hours_played'));
      expect(indexNames, contains('idx_games_rating'));
      expect(indexNames, contains('idx_games_status_updated'));
    });

    test('batchUpsertGames persiste un lote masivo dentro de una sola transacción atómica', () async {
      final games = List.generate(
        100,
        (i) => Game(
          id: 'batch-id-$i',
          title: 'Game #$i',
          hoursPlayed: (i * 2.5),
          genres: ['Acción', 'Aventura'],
          status: i % 2 == 0 ? 'Jugado' : 'Por jugar',
          steamId: 1000 + i,
        ),
      );

      final stopwatch = Stopwatch()..start();
      await DatabaseService.instance.batchUpsertGames(games);
      stopwatch.stop();

      final count = await DatabaseService.instance.getGameCount();
      expect(count, equals(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      final totalHours = await DatabaseService.instance.getTotalHours();
      expect(totalHours, greaterThan(0));
    });

    test('Ordenamiento case-insensitive (A-Z y Z-A) mediante title COLLATE NOCASE', () async {
      final games = [
        Game(title: 'zelda: Tears of the Kingdom'),
        Game(title: 'Animal Crossing'),
        Game(title: 'cyberpunk 2077'),
        Game(title: 'Baldur\'s Gate 3'),
      ];

      await DatabaseService.instance.batchUpsertGames(games);

      final azList = await DatabaseService.instance.getAllGames(sortBy: 'A-Z');
      expect(azList.first.title, equals('Animal Crossing'));
      expect(azList[1].title, equals('Baldur\'s Gate 3'));
      expect(azList[2].title, equals('cyberpunk 2077'));
      expect(azList.last.title, equals('zelda: Tears of the Kingdom'));

      final zaList = await DatabaseService.instance.getAllGames(sortBy: 'Z-A');
      expect(zaList.first.title, equals('zelda: Tears of the Kingdom'));
      expect(zaList.last.title, equals('Animal Crossing'));
    });

    test('CRUD básico y consultas por ID y Steam ID', () async {
      final game = Game(
        id: 'crud-1',
        title: 'Metroid Dread',
        platform: 'Nintendo Switch',
        hoursPlayed: 14.0,
        steamId: null,
      );

      await DatabaseService.instance.insertGame(game);
      final fetched = await DatabaseService.instance.getGameById('crud-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Metroid Dread'));

      final updated = fetched.copyWith(hoursPlayed: 16.5, status: 'Jugado');
      await DatabaseService.instance.updateGame(updated);

      final fetchedUpdated = await DatabaseService.instance.getGameById('crud-1');
      expect(fetchedUpdated!.hoursPlayed, equals(16.5));
      expect(fetchedUpdated.status, equals('Jugado'));

      await DatabaseService.instance.deleteGame('crud-1');
      final fetchedDeleted = await DatabaseService.instance.getGameById('crud-1');
      expect(fetchedDeleted, isNull);
    });
  });
}
