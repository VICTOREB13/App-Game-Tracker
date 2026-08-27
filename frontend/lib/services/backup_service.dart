import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import '../models/game.dart';
import 'database_service.dart';

class BackupService {
  /// Obtiene el directorio de Descargas adecuado según el sistema operativo
  static Directory _getDownloadsDirectory() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final dir = Directory('$userProfile\\Downloads');
      if (dir.existsSync()) return dir;
    } else if (Platform.isAndroid) {
      final primaryDownload = Directory('/storage/emulated/0/Download');
      if (primaryDownload.existsSync()) return primaryDownload;
      final altDownload = Directory('/sdcard/Download');
      if (altDownload.existsSync()) return altDownload;
    }
    return Directory.current;
  }

  /// Exporta la biblioteca completa de SQLite a un archivo JSON en Descargas
  static Future<String> exportBackup() async {
    final db = DatabaseService.instance;
    final games = await db.getAllGames();

    if (games.isEmpty) {
      throw Exception('No hay videojuegos en la biblioteca para exportar.');
    }

    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'tracker_backup_$dateStr.json';

    final downloadsDir = _getDownloadsDirectory();
    final filePath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';

    final payload = {
      'app': 'Victor Engineer - Game Tracker',
      'version': '3.0.0',
      'exported_at': now.toIso8601String(),
      'total_records': games.length,
      'games': games.map((g) => g.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final file = File(filePath);
    await file.writeAsString(jsonString, encoding: utf8);

    return file.path;
  }

  /// Importa y restaura una biblioteca desde un archivo JSON
  static Future<int> importBackupFromFile(File file) async {
    if (!await file.exists()) {
      throw Exception('El archivo seleccionado no existe.');
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

    // Persistir todos los juegos en SQLite en una sola transacción ultrarrápida
    await DatabaseService.instance.batchUpsertGames(gamesToRestore);

    return gamesToRestore.length;
  }

  /// Lista los respaldos existentes disponibles en el directorio de Descargas
  static Future<List<File>> getAvailableBackups() async {
    try {
      final downloadsDir = _getDownloadsDirectory();
      if (!downloadsDir.existsSync()) return [];

      final files = downloadsDir
          .listSync()
          .whereType<File>()
          .where((f) {
            final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
            return (name.startsWith('tracker_backup_') || name.startsWith('sample_games_')) &&
                name.endsWith('.json');
          })
          .toList();

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (_) {
      return [];
    }
  }
}
