import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/game.dart';

/// Servicio central de persistencia local SQLite para Windows Desktop y Android.
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Inicializa el motor SQLite adecuado según el sistema operativo con memoización
  /// para prevenir condiciones de carrera y aperturas simultáneas de la base de datos.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    if (_initFuture != null) {
      return await _initFuture!;
    }
    _initFuture = _initDatabase();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    // En Windows y Linux se requiere el driver FFI C
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'app_game_tracker.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await _createIndices(db);
  }

  Future<void> _createIndices(DatabaseExecutor db) async {
    // Índices B-Tree para búsquedas, filtros y ordenamientos en < 2 ms
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_steam_id ON games(steam_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_platform ON games(platform);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_title ON games(title);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_title_nocase ON games(title COLLATE NOCASE);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_updated_at ON games(updated_at DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_hours_played ON games(hours_played DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_rating ON games(rating DESC, hours_played DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_games_status_updated ON games(status, updated_at DESC);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIndices(db);
    }
  }

  /// Obtiene la ruta física del archivo SQLite en disco
  Future<String> getDatabasePath() async {
    if (_database != null && _database!.path.isNotEmpty) {
      return _database!.path;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      return p.join(directory.path, 'app_game_tracker.db');
    } catch (_) {
      return 'app_game_tracker.db';
    }
  }

  /// Recupera todos los juegos con soporte para filtros, ordenamientos y paginación SQL
  Future<List<Game>> getAllGames({
    String? status,
    String? platform,
    String? genre,
    String? search,
    String sortBy = 'Recientes',
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status != 'Todos') {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    if (platform != null && platform != 'Todas') {
      whereConditions.add('platform = ?');
      whereArgs.add(platform);
    }

    if (search != null && search.trim().isNotEmpty) {
      whereConditions.add('LOWER(title) LIKE ?');
      whereArgs.add('%${search.trim().toLowerCase()}%');
    }

    String orderBy;
    switch (sortBy) {
      case 'A-Z':
        orderBy = 'title COLLATE NOCASE ASC';
        break;
      case 'Z-A':
        orderBy = 'title COLLATE NOCASE DESC';
        break;
      case 'Horas (Mayor)':
        orderBy = 'hours_played DESC';
        break;
      case 'Calificación':
        orderBy = 'rating DESC, hours_played DESC';
        break;
      case 'Recientes':
      default:
        orderBy = 'updated_at DESC';
        break;
    }

    final whereClause = whereConditions.isNotEmpty
        ? whereConditions.join(' AND ')
        : null;

    final records = await db.query(
      'games',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    List<Game> games = records.map((m) => Game.fromSqliteMap(m)).toList();

    // Filtro en memoria para géneros (ya que están serializados como JSON)
    if (genre != null && genre != 'Todos') {
      games = games.where((g) {
        return g.genres.any((item) =>
            item.trim().toLowerCase() == genre.trim().toLowerCase());
      }).toList();
    }

    return games;
  }

  /// Obtiene un juego por su ID único
  Future<Game?> getGameById(String id) async {
    final db = await database;
    final res = await db.query('games', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return Game.fromSqliteMap(res.first);
    }
    return null;
  }

  /// Obtiene un juego por su Steam AppID
  Future<Game?> getGameBySteamId(num steamId) async {
    final db = await database;
    final res = await db.query(
      'games',
      where: 'steam_id = ?',
      whereArgs: [steamId.toInt()],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return Game.fromSqliteMap(res.first);
    }
    return null;
  }

  /// Inserta un nuevo juego en SQLite
  Future<void> insertGame(Game game) async {
    final db = await database;
    await db.insert(
      'games',
      game.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza un juego existente en SQLite
  Future<void> updateGame(Game game) async {
    final db = await database;
    await db.update(
      'games',
      game.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  /// Elimina un juego por ID
  Future<void> deleteGame(String id) async {
    final db = await database;
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Inserta o actualiza un lote de juegos en una sola transacción atómica rápida
  Future<void> batchUpsertGames(List<Game> games) async {
    if (games.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final game in games) {
        batch.insert(
          'games',
          game.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Retorna el conteo total de títulos almacenados
  Future<int> getGameCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM games');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Retorna la sumatoria total de horas registradas
  Future<double> getTotalHours() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(hours_played) as total FROM games');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Optimiza el archivo SQLite reduciendo espacio libre
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Borra todos los juegos (útil para pruebas o reinicio total)
  Future<void> clearAllGames() async {
    final db = await database;
    await db.delete('games');
  }

  /// Cierra la base de datos y reinicia los futuros de inicialización (útil para pruebas)
  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initFuture = null;
  }

  /// Inyecta una base de datos abierta para pruebas unitarias
  @visibleForTesting
  void setDatabaseForTesting(Database testDb) {
    _database = testDb;
    _initFuture = Future.value(testDb);
  }
}
