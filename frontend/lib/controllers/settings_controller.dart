import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/metadata_service.dart';
import '../services/secure_storage_service.dart';
import '../services/steam_service.dart';

/// Controlador central de configuración, credenciales y sincronizaciones bajo el patrón MVC.
///
/// Encapsula:
/// - Gestión segura de claves de API (Steam, RAWG, Notion) con [SecureStorageService].
/// - Operaciones de sincronización masiva en lote (Steam, HowLongToBeat, Metadatos).
/// - Respaldo, exportación e importación de la base de datos con [BackupService].
/// - Mantenimiento, optimización (VACUUM) y reseteo de SQLite con [DatabaseService].
class SettingsController extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final DatabaseService _dbService;
  final SteamService _steamService;
  final MetadataService _metadataService;
  SharedPreferences? _prefs;

  static const String keySteamUserId = 'steam_user_id';

  // --- Credenciales y Claves ---
  String _rawgApiKey = '';
  String _steamApiKey = '';
  String _steamUserId = '';
  String _notionToken = '';

  // --- Métricas de Base de Datos ---
  int _gameCount = 0;
  double _totalHours = 0.0;
  String _databasePath = '';

  // --- Estados de Carga y Sincronización ---
  bool _isLoading = true;
  bool _isTestingSteam = false;
  bool _isSyncingSteam = false;
  bool _isSyncingHltb = false;
  bool _isSyncingMetadata = false;
  bool _isExportingBackup = false;
  bool _isImportingBackup = false;
  bool _isOptimizingDb = false;
  bool _isClearingDb = false;
  String? _errorMessage;
  String? _feedbackMessage;

  SettingsController({
    SecureStorageService? secureStorage,
    DatabaseService? dbService,
    SteamService? steamService,
    MetadataService? metadataService,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _dbService = dbService ?? DatabaseService.instance,
        _steamService = steamService ?? SteamService.instance,
        _metadataService = metadataService ?? MetadataService.instance,
        _prefs = prefs;

  // ===========================================================================
  // Getters Públicos
  // ===========================================================================

  String get rawgApiKey => _rawgApiKey;
  String get steamApiKey => _steamApiKey;
  String get steamUserId => _steamUserId;
  String get notionToken => _notionToken;

  int get gameCount => _gameCount;
  double get totalHours => _totalHours;
  String get databasePath => _databasePath;

  bool get isLoading => _isLoading;
  bool get isTestingSteam => _isTestingSteam;
  bool get isSyncingSteam => _isSyncingSteam;
  bool get isSyncingHltb => _isSyncingHltb;
  bool get isSyncingMetadata => _isSyncingMetadata;
  bool get isExportingBackup => _isExportingBackup;
  bool get isImportingBackup => _isImportingBackup;
  bool get isOptimizingDb => _isOptimizingDb;
  bool get isClearingDb => _isClearingDb;

  String? get errorMessage => _errorMessage;
  String? get feedbackMessage => _feedbackMessage;

  // ===========================================================================
  // Carga de Ajustes y Métricas
  // ===========================================================================

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Carga todas las credenciales almacenadas y el estado actual de la base de datos.
  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      final count = await _dbService.getGameCount();
      final hours = await _dbService.getTotalHours();
      final path = await _dbService.getDatabasePath();

      final rawg = await _secureStorage.getRawgKey();
      final steam = await _secureStorage.getSteamApiKey();
      final notion = await _secureStorage.getNotionToken();
      final steamId = prefs.getString(keySteamUserId) ?? '';

      _rawgApiKey = rawg ?? '';
      _steamApiKey = steam ?? '';
      _steamUserId = steamId;
      _notionToken = notion ?? '';
      _gameCount = count;
      _totalHours = hours;
      _databasePath = path;
    } catch (e) {
      debugPrint('[SettingsController] Error cargando ajustes: $e');
      _errorMessage = 'Error al cargar ajustes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Gestión de Credenciales Seguras
  // ===========================================================================

  /// Guarda de forma segura la RAWG API Key.
  Future<void> saveRawgKey(String key) async {
    final cleanKey = key.trim();
    _errorMessage = null;
    try {
      if (cleanKey.isEmpty) {
        await _secureStorage.deleteRawgKey();
        _rawgApiKey = '';
      } else {
        await _secureStorage.setRawgKey(cleanKey);
        _rawgApiKey = cleanKey;
      }
      _feedbackMessage = 'RAWG API Key guardada con éxito.';
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsController] Error guardando RAWG key: $e');
      _errorMessage = 'Error al guardar la RAWG API Key: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Guarda las credenciales de Steam (API Key en almacén cifrado y SteamID en preferencias).
  Future<void> saveSteamSettings({
    required String apiKey,
    required String steamId,
  }) async {
    final cleanKey = apiKey.trim();
    final cleanId = steamId.trim();
    _errorMessage = null;

    try {
      if (cleanKey.isEmpty) {
        await _secureStorage.deleteSteamApiKey();
        _steamApiKey = '';
      } else {
        await _secureStorage.setSteamApiKey(cleanKey);
        _steamApiKey = cleanKey;
      }

      final prefs = await _getPrefs();
      if (cleanId.isEmpty) {
        await prefs.remove(keySteamUserId);
        _steamUserId = '';
      } else {
        await prefs.setString(keySteamUserId, cleanId);
        _steamUserId = cleanId;
      }

      _feedbackMessage = 'Credenciales de Steam guardadas con éxito.';
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsController] Error guardando ajustes Steam: $e');
      _errorMessage = 'Error al guardar credenciales de Steam: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Guarda de forma segura el token de integración de Notion.
  Future<void> saveNotionToken(String token) async {
    final cleanToken = token.trim();
    _errorMessage = null;

    try {
      if (cleanToken.isEmpty) {
        await _secureStorage.deleteNotionToken();
        _notionToken = '';
      } else {
        await _secureStorage.setNotionToken(cleanToken);
        _notionToken = cleanToken;
      }
      _feedbackMessage = 'Token de Notion guardado con éxito.';
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsController] Error guardando token de Notion: $e');
      _errorMessage = 'Error al guardar token de Notion: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ===========================================================================
  // Validación y Resolución de Steam
  // ===========================================================================

  /// Valida la conexión con la Web API de Steam.
  Future<bool> testSteamConnection({String? apiKey, String? steamId}) async {
    final key = (apiKey ?? _steamApiKey).trim();
    final id = (steamId ?? _steamUserId).trim();

    if (key.isEmpty || id.isEmpty) {
      _errorMessage = 'Ingresa tu Steam Web API Key y SteamID para probar la conexión.';
      notifyListeners();
      return false;
    }

    _isTestingSteam = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _steamService.validateCredentials(key, id);
      _feedbackMessage = isValid
          ? 'Conexión con Steam validada exitosamente.'
          : 'No se pudo validar la conexión con Steam.';
      return isValid;
    } catch (e) {
      debugPrint('[SettingsController] Error probando conexión Steam: $e');
      _errorMessage = 'Error conectando con Steam: $e';
      return false;
    } finally {
      _isTestingSteam = false;
      notifyListeners();
    }
  }

  /// Resuelve un vanity URL (nombre personalizado) al SteamID64 canónico de 17 dígitos.
  Future<String?> resolveSteamVanity(String vanityOrId, {String? apiKey}) async {
    final key = (apiKey ?? _steamApiKey).trim();
    final idOrVanity = vanityOrId.trim();

    if (key.isEmpty || idOrVanity.isEmpty) {
      _errorMessage = 'Ingresa la API Key y el perfil de Steam para resolver.';
      notifyListeners();
      return null;
    }

    try {
      final resolved = await _steamService.resolveVanityUrl(key, idOrVanity);
      if (resolved != null) {
        _steamUserId = resolved;
        final prefs = await _getPrefs();
        await prefs.setString(keySteamUserId, resolved);
        _feedbackMessage = 'SteamID64 detectado y guardado: $resolved';
        notifyListeners();
      }
      return resolved;
    } catch (e) {
      debugPrint('[SettingsController] Error resolviendo vanity URL: $e');
      _errorMessage = 'Error resolviendo nombre de Steam: $e';
      notifyListeners();
      return null;
    }
  }

  // ===========================================================================
  // Sincronizaciones Masivas
  // ===========================================================================

  /// Ejecuta la sincronización completa de la biblioteca de Steam en dos fases.
  Future<SteamSyncResult> syncSteam() async {
    final key = _steamApiKey.trim();
    final id = _steamUserId.trim();

    if (key.isEmpty || id.isEmpty) {
      throw Exception('Guarda tus credenciales de Steam antes de sincronizar.');
    }

    _isSyncingSteam = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _steamService.syncWithDatabase(
        apiKey: key,
        steamId: id,
      );
      await loadSettings();
      _feedbackMessage = 'Sincronización con Steam completada.';
      return result;
    } catch (e) {
      debugPrint('[SettingsController] Error en sincronización Steam: $e');
      _errorMessage = 'Error en sincronización Steam: $e';
      rethrow;
    } finally {
      _isSyncingSteam = false;
      notifyListeners();
    }
  }

  /// Sincroniza la duración de campaña y completista desde HowLongToBeat para los juegos pendientes.
  Future<Map<String, int>> syncAllHltb({
    bool onlyPending = true,
    void Function(int current, int total, String title)? onProgress,
  }) async {
    _isSyncingHltb = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allGames = await _dbService.getAllGames();
      final stats = await _metadataService.syncAllHltbGames(
        games: allGames,
        onlyPending: onlyPending,
        onProgress: onProgress,
      );
      await loadSettings();
      _feedbackMessage = 'Sincronización de HowLongToBeat completada.';
      return stats;
    } catch (e) {
      debugPrint('[SettingsController] Error sincronizando HLTB: $e');
      _errorMessage = 'Error en sincronización HLTB: $e';
      rethrow;
    } finally {
      _isSyncingHltb = false;
      notifyListeners();
    }
  }

  /// Sincroniza metadatos faltantes (géneros RAWG, enlaces de Wikipedia y portadas HD).
  Future<Map<String, int>> syncAllMetadata({
    bool onlyPending = true,
    void Function(int current, int total, String title)? onProgress,
  }) async {
    final rawg = _rawgApiKey.trim();
    if (rawg.isEmpty) {
      throw Exception('Configura tu RAWG API Key antes de sincronizar metadatos.');
    }

    _isSyncingMetadata = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allGames = await _dbService.getAllGames();
      final stats = await _metadataService.syncAllGamesMetadata(
        games: allGames,
        rawgKey: rawg,
        onlyPending: onlyPending,
        onProgress: onProgress,
      );
      await loadSettings();
      _feedbackMessage = 'Sincronización de metadatos completada.';
      return stats;
    } catch (e) {
      debugPrint('[SettingsController] Error sincronizando metadatos: $e');
      _errorMessage = 'Error en sincronización de metadatos: $e';
      rethrow;
    } finally {
      _isSyncingMetadata = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Respaldos y Restauración JSON
  // ===========================================================================

  /// Exporta la biblioteca completa a un archivo JSON seguro.
  Future<String> exportBackup({
    String? customPath,
    String? customDirectoryPath,
  }) async {
    _isExportingBackup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final path = await BackupService.exportBackup(
        customPath: customPath,
        customDirectoryPath: customDirectoryPath,
      );
      _feedbackMessage = 'Respaldo exportado exitosamente en:\n$path';
      return path;
    } catch (e) {
      debugPrint('[SettingsController] Error exportando respaldo: $e');
      _errorMessage = 'Error al exportar respaldo: $e';
      rethrow;
    } finally {
      _isExportingBackup = false;
      notifyListeners();
    }
  }

  /// Importa y restaura una biblioteca desde un archivo JSON.
  Future<int> importBackupFromFile(File file) async {
    _isImportingBackup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await BackupService.importBackupFromFile(file);
      await loadSettings();
      _feedbackMessage = 'Se restauraron $count juegos en SQLite exitosamente.';
      return count;
    } catch (e) {
      debugPrint('[SettingsController] Error importando archivo de respaldo: $e');
      _errorMessage = 'Error al importar respaldo: $e';
      rethrow;
    } finally {
      _isImportingBackup = false;
      notifyListeners();
    }
  }

  /// Importa y restaura una biblioteca desde un texto JSON directo.
  Future<int> importBackupFromJsonString(String jsonContent) async {
    _isImportingBackup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await BackupService.importBackupFromJsonString(jsonContent);
      await loadSettings();
      _feedbackMessage = 'Se restauraron $count juegos en SQLite exitosamente.';
      return count;
    } catch (e) {
      debugPrint('[SettingsController] Error importando cadena JSON: $e');
      _errorMessage = 'Error al importar respaldo JSON: $e';
      rethrow;
    } finally {
      _isImportingBackup = false;
      notifyListeners();
    }
  }

  /// Lista los respaldos disponibles en las carpetas estándar del sistema.
  Future<List<File>> getAvailableBackups() async {
    try {
      return await BackupService.getAvailableBackups();
    } catch (e) {
      debugPrint('[SettingsController] Error listando respaldos: $e');
      return [];
    }
  }

  // ===========================================================================
  // Mantenimiento y Reseteo de Base de Datos
  // ===========================================================================

  /// Optimiza la base de datos SQLite ejecutando VACUUM para compactar el almacenamiento.
  Future<void> optimizeDatabase() async {
    _isOptimizingDb = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbService.vacuum();
      await loadSettings();
      _feedbackMessage = 'Base de datos SQLite compactada y optimizada exitosamente.';
    } catch (e) {
      debugPrint('[SettingsController] Error optimizando SQLite: $e');
      _errorMessage = 'Error al optimizar la base de datos: $e';
      rethrow;
    } finally {
      _isOptimizingDb = false;
      notifyListeners();
    }
  }

  /// Limpia y borra todos los registros de videojuegos en la tabla `games`.
  Future<void> clearAllGames() async {
    _isClearingDb = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbService.clearAllGames();
      await loadSettings();
      _feedbackMessage = 'Todos los juegos han sido eliminados de la base de datos.';
    } catch (e) {
      debugPrint('[SettingsController] Error limpiando juegos: $e');
      _errorMessage = 'Error al vaciar la base de datos: $e';
      rethrow;
    } finally {
      _isClearingDb = false;
      notifyListeners();
    }
  }
}
