import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tracker_app/models/game.dart';
import 'package:tracker_app/services/backup_service.dart';
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

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('BackupService Tests', () {
    test('Importación de formato canónico v3.0 ("games")', () async {
      final jsonPayload = json.encode({
        'app': 'Victor Engineer - Game Tracker',
        'version': '3.1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'total_records': 2,
        'games': [
          {
            'id': 'g1',
            'title': 'Sekiro: Shadows Die Twice',
            'hours_played': 70.5,
            'status': 'Jugado',
            'platform': 'PC',
            'genres': ['Acción', 'Souls-like'],
          },
          {
            'id': 'g2',
            'title': 'Celeste',
            'hours_played': 18.0,
            'status': 'Jugado',
            'platform': 'PC',
            'genres': ['Plataformas', 'Indie'],
          }
        ]
      });

      final count = await BackupService.importBackupFromJsonString(jsonPayload);
      expect(count, equals(2));

      final games = await DatabaseService.instance.getAllGames();
      expect(games.length, equals(2));
      expect(games.any((g) => g.title == 'Sekiro: Shadows Die Twice'), isTrue);
      expect(games.any((g) => g.title == 'Celeste'), isTrue);
    });

    test('Importación de formato heredado Notion v2.x ("records")', () async {
      final legacyPayload = json.encode({
        'version': '2.4.0',
        'records': [
          {
            'id': 'notion-1',
            'properties': {
              'Título': {
                'title': [
                  {'plain_text': 'Chrono Trigger'}
                ]
              },
              'Estado': {'select': {'name': 'Jugado'}},
              'Horas Jugadas': {'number': 25.0},
              'Plataforma': {'select': {'name': 'SNES'}},
              'Géneros': {
                'multi_select': [
                  {'name': 'JRPG'},
                  {'name': 'Clásico'}
                ]
              }
            }
          }
        ]
      });

      final count = await BackupService.importBackupFromJsonString(legacyPayload);
      expect(count, equals(1));

      final restored = await DatabaseService.instance.getGameById('notion-1');
      expect(restored, isNotNull);
      expect(restored!.title, equals('Chrono Trigger'));
      expect(restored.platform, equals('SNES'));
      expect(restored.hoursPlayed, equals(25.0));
      expect(restored.genres, contains('JRPG'));
    });

    test('Exportación e Importación de archivo temporal valida integridad', () async {
      final game = Game(
        id: 'export-1',
        title: 'Super Mario Odyssey',
        platform: 'Nintendo Switch',
        hoursPlayed: 35.0,
        status: 'Jugado',
      );
      await DatabaseService.instance.insertGame(game);

      final tempDir = Directory.systemTemp.createTempSync('tracker_backup_test_');
      final exportPath = '${tempDir.path}${Platform.pathSeparator}test_backup.json';

      final resultPath = await BackupService.exportBackup(customPath: exportPath);
      expect(resultPath, equals(exportPath));
      final exportedFile = File(resultPath);
      expect(exportedFile.existsSync(), isTrue);

      // Limpiar BD
      await DatabaseService.instance.clearAllGames();
      expect(await DatabaseService.instance.getGameCount(), equals(0));

      // Restaurar desde archivo
      final restoredCount = await BackupService.importBackupFromFile(exportedFile);
      expect(restoredCount, equals(1));

      final restoredGame = await DatabaseService.instance.getGameById('export-1');
      expect(restoredGame, isNotNull);
      expect(restoredGame!.title, equals('Super Mario Odyssey'));

      tempDir.deleteSync(recursive: true);
    });
  });
}
