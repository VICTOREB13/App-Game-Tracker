import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado de almacenamiento seguro y cifrado para claves sensibles
/// (Steam Web API Key, RAWG API Key, Notion Token).
///
/// Utiliza:
/// - Android: Keystore / EncryptedSharedPreferences (AES-256 + RSA)
/// - Windows: DPAPI (Data Protection API)
/// - iOS / macOS: Apple Keychain (first_unlock accessibility)
class SecureStorageService {
  static SecureStorageService? _instance;

  final FlutterSecureStorage _storage;

  // Claves canónicas para credenciales
  static const String keySteamApiKey = 'steam_api_key';
  static const String keyRawgKey = 'rawg_key';
  static const String keyNotionToken = 'notion_token';

  // Clave legada alternativa para RAWG encontrada en versiones anteriores
  static const String keyLegacyRawgApiKey = 'rawg_api_key';

  // Flag de control de migración completada
  static const String keyMigrationCompleted = 'secure_storage_migration_completed_v1';

  SecureStorageService._({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              wOptions: WindowsOptions(),
            );

  /// Obtiene la instancia singleton de [SecureStorageService].
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// Permite inyectar o sobrescribir la instancia (útil para pruebas unitarias).
  @visibleForTesting
  static void setInstanceForTesting(SecureStorageService? testInstance) {
    _instance = testInstance;
  }

  /// Constructor para testing que permite inyectar un [FlutterSecureStorage] personalizado.
  @visibleForTesting
  factory SecureStorageService.custom(FlutterSecureStorage storage) {
    return SecureStorageService._(storage: storage);
  }

  // ==========================================
  // Operaciones Genéricas
  // ==========================================

  /// Escribe un par clave-valor de forma segura y cifrada.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error escribiendo en SecureStorage [$key]: $e');
      rethrow;
    }
  }

  /// Lee el valor asociado a una clave del almacenamiento seguro.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Error leyendo de SecureStorage [$key]: $e');
      return null;
    }
  }

  /// Elimina una clave del almacenamiento seguro.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('Error eliminando de SecureStorage [$key]: $e');
      rethrow;
    }
  }

  /// Elimina todas las claves del almacenamiento seguro.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error limpiando SecureStorage: $e');
      rethrow;
    }
  }

  /// Verifica si una clave existe en el almacenamiento seguro.
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('Error verificando existencia en SecureStorage [$key]: $e');
      return false;
    }
  }

  /// Retorna un mapa con todos los pares clave-valor seguros.
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('Error leyendo todas las entradas de SecureStorage: $e');
      return {};
    }
  }

  // ==========================================
  // Helpers Tipados para Claves Específicas
  // ==========================================

  // --- Steam Web API Key ---
  Future<String?> getSteamApiKey() async {
    final key = await read(keySteamApiKey);
    return (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  Future<void> setSteamApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await deleteSteamApiKey();
    } else {
      await write(keySteamApiKey, trimmed);
    }
  }

  Future<void> deleteSteamApiKey() async {
    await delete(keySteamApiKey);
  }

  // --- RAWG API Key ---
  Future<String?> getRawgKey() async {
    final key = await read(keyRawgKey);
    return (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  Future<void> setRawgKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await deleteRawgKey();
    } else {
      await write(keyRawgKey, trimmed);
    }
  }

  Future<void> deleteRawgKey() async {
    await delete(keyRawgKey);
  }

  // --- Notion Integration Token ---
  Future<String?> getNotionToken() async {
    final token = await read(keyNotionToken);
    return (token != null && token.trim().isNotEmpty) ? token.trim() : null;
  }

  Future<void> setNotionToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await deleteNotionToken();
    } else {
      await write(keyNotionToken, trimmed);
    }
  }

  Future<void> deleteNotionToken() async {
    await delete(keyNotionToken);
  }

  // ==========================================
  // Migración Transparente desde SharedPreferences
  // ==========================================

  /// Migra automáticamente credenciales sensibles no cifradas desde [SharedPreferences]
  /// hacia [SecureStorageService], purgándolas posteriormente de [SharedPreferences].
  ///
  /// Claves migradas:
  /// - `steam_api_key` -> `SecureStorageService.keySteamApiKey`
  /// - `rawg_key` / `rawg_api_key` -> `SecureStorageService.keyRawgKey`
  /// - `notion_token` -> `SecureStorageService.keyNotionToken`
  ///
  /// Esta operación es idempotente y segura ante fallos parciales.
  Future<void> migrateFromSharedPreferences({SharedPreferences? prefsInstance}) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();

      // 1. Migrar Steam Web API Key
      if (prefs.containsKey(keySteamApiKey)) {
        final steamKey = prefs.getString(keySteamApiKey)?.trim();
        if (steamKey != null && steamKey.isNotEmpty) {
          final existing = await getSteamApiKey();
          if (existing == null || existing.isEmpty) {
            await setSteamApiKey(steamKey);
          }
        }
        await prefs.remove(keySteamApiKey);
        debugPrint('[SecureStorageService] Migrada y purgada steam_api_key de SharedPreferences');
      }

      // 2. Migrar RAWG API Key (soporta 'rawg_key' y 'rawg_api_key')
      String? rawgKey;
      if (prefs.containsKey(keyRawgKey)) {
        rawgKey = prefs.getString(keyRawgKey)?.trim();
        await prefs.remove(keyRawgKey);
      }
      if (prefs.containsKey(keyLegacyRawgApiKey)) {
        final legacyKey = prefs.getString(keyLegacyRawgApiKey)?.trim();
        rawgKey ??= legacyKey;
        await prefs.remove(keyLegacyRawgApiKey);
      }
      if (rawgKey != null && rawgKey.isNotEmpty) {
        final existing = await getRawgKey();
        if (existing == null || existing.isEmpty) {
          await setRawgKey(rawgKey);
        }
        debugPrint('[SecureStorageService] Migrada y purgada rawg_key de SharedPreferences');
      }

      // 3. Migrar Notion Integration Token
      if (prefs.containsKey(keyNotionToken)) {
        final notionToken = prefs.getString(keyNotionToken)?.trim();
        if (notionToken != null && notionToken.isNotEmpty) {
          final existing = await getNotionToken();
          if (existing == null || existing.isEmpty) {
            await setNotionToken(notionToken);
          }
        }
        await prefs.remove(keyNotionToken);
        debugPrint('[SecureStorageService] Migrado y purgado notion_token de SharedPreferences');
      }

      // Marcar migración como completada
      await prefs.setBool(keyMigrationCompleted, true);
    } catch (e, stack) {
      debugPrint('[SecureStorageService] Error durante migración desde SharedPreferences: $e\n$stack');
    }
  }
}
