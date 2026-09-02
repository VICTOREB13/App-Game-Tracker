import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/game.dart';
import 'database_service.dart';

/// Servicio de exportación e importación de respaldos JSON multiplataforma.
/// Utiliza resolución dinámica de almacenamiento seguro (Scoped Storage en Android 10+
/// y directorios estándar del usuario en Windows Desktop).
class BackupService {
  /// Resuelve dinámicamente el directorio seguro más adecuado para guardar respaldos
  static Future<Directory> _resolveBackupDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null && await downloads.exists()) {
        return downloads;
      }
    } catch (_) {}

    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && await extDir.exists()) {
          return extDir;
        }
      }
    } catch (_) {}

    final docs = await getApplicationDocumentsDirectory();
    if (!await docs.exists()) {
      await docs.create(recursive: true);
    }
    return docs;
  }

  /// Exporta la biblioteca completa de SQLite a un archivo JSON seguro
  static Future<String> exportBackup({String? customPath, String? customDirectoryPath}) async {
    final db = DatabaseService.instance;
    final games = await db.getAllGames();

    if (games.isEmpty) {
      throw Exception('No hay videojuegos en la biblioteca para exportar.');
    }

    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'tracker_backup_$dateStr.json';

    String targetFilePath;
    if (customPath != null && customPath.trim().isNotEmpty) {
      targetFilePath = customPath.trim();
    } else if (customDirectoryPath != null && customDirectoryPath.trim().isNotEmpty) {
      targetFilePath = p.join(customDirectoryPath.trim(), fileName);
    } else {
      final dir = await _resolveBackupDirectory();
      targetFilePath = p.join(dir.path, fileName);
    }

    final targetFile = File(targetFilePath);
    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final payload = {
      'app': 'Victor Engineer - Game Tracker',
      'version': '3.1.0',
      'exported_at': now.toIso8601String(),
      'total_records': games.length,
      'games': games.map((g) => g.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    await targetFile.writeAsString(jsonString, encoding: utf8);

    return targetFile.path;
  }

  /// Importa y restaura una biblioteca desde un archivo JSON
  static Future<int> importBackupFromFile(File file) async {
    if (!await file.exists()) {
      throw Exception('El archivo seleccionado no existe: ${file.path}');
    }

    final content = await file.readAsString(encoding: utf8);
    return importBackupFromJsonString(content);
  }

  /// Importa y restaura una biblioteca desde una cadena de texto JSON
  /// Soporta tanto el formato canónico v3.0 ('games') como el formato heredado de Notion v2.x ('records').
  static Future<int> importBackupFromJsonString(String content) async {
    final decoded = json.decode(content);
    final List<Game> gamesToRestore = [];

    if (decoded is Map<String, dynamic>) {
      // 1. Formato Canónico v3.0 (SQLite)
      if (decoded.containsKey('games') && decoded['games'] is List) {
        final list = decoded['games'] as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            gamesToRestore.add(Game.fromJson(item));
          }
        }
      }
      // 2. Formato Heredado v2.x (Notion API Cache)
      else if (decoded.containsKey('records') && decoded['records'] is List) {
        final list = decoded['records'] as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            gamesToRestore.add(Game.fromLegacyNotion(item));
          }
        }
      }
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          if (item.containsKey('properties')) {
            gamesToRestore.add(Game.fromLegacyNotion(item));
          } else {
            gamesToRestore.add(Game.fromJson(item));
          }
        }
      }
    }

    if (gamesToRestore.isEmpty) {
      throw Exception('El archivo no contiene registros de videojuegos válidos.');
    }

    // Persistir todos los juegos en SQLite en una sola transacción atómica ultrarrápida
    await DatabaseService.instance.batchUpsertGames(gamesToRestore);

    return gamesToRestore.length;
  }

  /// Lista los respaldos existentes disponibles buscando dinámicamente en directorios del sistema
  static Future<List<File>> getAvailableBackups() async {
    final List<File> result = [];
    final Set<String> seenPaths = {};

    final candidateDirs = <Directory>[];

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null && await downloads.exists()) {
        candidateDirs.add(downloads);
      }
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      if (await docs.exists()) {
        candidateDirs.add(docs);
      }
    } catch (_) {}

    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && await extDir.exists()) {
          candidateDirs.add(extDir);
        }
      }
    } catch (_) {}

    // Directorio actual de la app (para sample_games_library.json)
    try {
      candidateDirs.add(Directory.current);
    } catch (_) {}

    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) continue;
        final list = dir.listSync();
        for (final entity in list) {
          if (entity is File) {
            final fileName = p.basename(entity.path).toLowerCase();
            if ((fileName.startsWith('tracker_backup_') || fileName.startsWith('sample_games_')) &&
                fileName.endsWith('.json')) {
              if (seenPaths.add(entity.path)) {
                result.add(entity);
              }
            }
          }
        }
      } catch (_) {}
    }

    result.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });

    return result;
  }
}
