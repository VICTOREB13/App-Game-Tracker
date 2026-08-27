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

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Inicializa el motor SQLite adecuado según el sistema operativo
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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
      version: 1,
      onCreate: _onCreate,
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

    // Índices B-Tree para búsquedas y ordenamientos en < 2 ms
    await db.execute('CREATE INDEX idx_games_steam_id ON games(steam_id)');
    await db.execute('CREATE INDEX idx_games_status ON games(status)');
    await db.execute('CREATE INDEX idx_games_platform ON games(platform)');
    await db.execute('CREATE INDEX idx_games_title ON games(title)');
  }

  /// Obtiene la ruta física del archivo SQLite en disco
  Future<String> getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'app_game_tracker.db');
  }

  /// Recupera todos los juegos con soporte para filtros y ordenamientos
  Future<List<Game>> getAllGames({
    String? status,
    String? platform,
    String? genre,
    String? search,
    String sortBy = 'Recientes',
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

  /// Inserta o actualiza un lote de juegos en una sola transacción rápida
  Future<void> batchUpsertGames(List<Game> games) async {
    final db = await database;
    final batch = db.batch();

    for (final game in games) {
      batch.insert(
        'games',
        game.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
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
}
