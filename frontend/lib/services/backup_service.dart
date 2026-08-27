import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'notion_service.dart';

class BackupService {
  /// Obtiene el directorio de Descargas adecuado según la plataforma
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

  /// Exporta la biblioteca completa de juegos a un archivo JSON en Descargas
  static Future<String> exportBackup() async {
    final notion = NotionService.instance;
    List<Map<String, dynamic>>? records = await notion.getLocalCache();

    // Si la caché local está vacía, intentar obtener los juegos
    if (records == null || records.isEmpty) {
      records = await notion.getGames(useCache: true);
    }

    if (records.isEmpty) {
      throw Exception('No hay juegos en la biblioteca para exportar.');
    }

    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'tracker_backup_$dateStr.json';

    final downloadsDir = _getDownloadsDirectory();
    final filePath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';

    final payload = {
      'app': 'Victor Engineer Entertainment Tracker',
      'version': '2.8.0',
      'exported_at': now.toIso8601String(),
      'total_records': records.length,
      'records': records,
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
  static Future<int> importBackupFromJsonString(String content) async {
    final decoded = json.decode(content);
    List<dynamic>? rawList;

    if (decoded is Map<String, dynamic> && decoded.containsKey('records')) {
      rawList = decoded['records'] as List<dynamic>?;
    } else if (decoded is List<dynamic>) {
      rawList = decoded;
    }

    if (rawList == null || rawList.isEmpty) {
      throw Exception('El archivo no contiene registros válidos de la biblioteca.');
    }

    final records = rawList
        .whereType<Map<String, dynamic>>()
        .toList();

    if (records.isEmpty) {
      throw Exception('No se pudieron procesar los registros del archivo.');
    }

    // Guardar en la caché local persistente
    await NotionService.instance.saveLocalCache(records);

    return records.length;
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
            return name.startsWith('tracker_backup_') && name.endsWith('.json');
          })
          .toList();

      // Ordenar del más reciente al más antiguo
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (_) {
      return [];
    }
  }
}
