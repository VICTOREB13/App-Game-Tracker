import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker_app/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService Tests', () {
    late SecureStorageService secureStorage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      secureStorage = SecureStorageService.instance;
      SecureStorageService.setInstanceForTesting(secureStorage);
    });

    tearDown(() async {
      await secureStorage.deleteAll();
    });

    test('CRUD básico de pares clave-valor', () async {
      await secureStorage.write('test_key', 'test_value');
      final val = await secureStorage.read('test_key');
      expect(val, equals('test_value'));

      final exists = await secureStorage.containsKey('test_key');
      expect(exists, isTrue);

      await secureStorage.delete('test_key');
      final deletedVal = await secureStorage.read('test_key');
      expect(deletedVal, isNull);

      final notExists = await secureStorage.containsKey('test_key');
      expect(notExists, isFalse);
    });

    test('Getters y Setters tipados para Steam API Key', () async {
      expect(await secureStorage.getSteamApiKey(), isNull);

      await secureStorage.setSteamApiKey('STEAM_SECRET_KEY_123');
      expect(await secureStorage.getSteamApiKey(), equals('STEAM_SECRET_KEY_123'));

      // Asignar cadena vacía debe eliminar la clave
      await secureStorage.setSteamApiKey('   ');
      expect(await secureStorage.getSteamApiKey(), isNull);

      await secureStorage.setSteamApiKey('STEAM_SECRET_KEY_456');
      await secureStorage.deleteSteamApiKey();
      expect(await secureStorage.getSteamApiKey(), isNull);
    });

    test('Getters y Setters tipados para RAWG API Key', () async {
      expect(await secureStorage.getRawgKey(), isNull);

      await secureStorage.setRawgKey('rawg_secret_999');
      expect(await secureStorage.getRawgKey(), equals('rawg_secret_999'));

      // Asignar cadena vacía debe eliminar la clave
      await secureStorage.setRawgKey('');
      expect(await secureStorage.getRawgKey(), isNull);

      await secureStorage.setRawgKey('rawg_secret_888');
      await secureStorage.deleteRawgKey();
      expect(await secureStorage.getRawgKey(), isNull);
    });

    test('Getters y Setters tipados para Notion Token', () async {
      expect(await secureStorage.getNotionToken(), isNull);

      await secureStorage.setNotionToken('ntn_secret_token_abc');
      expect(await secureStorage.getNotionToken(), equals('ntn_secret_token_abc'));

      // Asignar cadena vacía debe eliminar la clave
      await secureStorage.setNotionToken('  ');
      expect(await secureStorage.getNotionToken(), isNull);

      await secureStorage.setNotionToken('ntn_secret_token_def');
      await secureStorage.deleteNotionToken();
      expect(await secureStorage.getNotionToken(), isNull);
    });

    test('Migración transparente desde SharedPreferences purga datos planos', () async {
      SharedPreferences.setMockInitialValues({
        'steam_api_key': 'legacy_steam_key_777',
        'rawg_key': 'legacy_rawg_key_888',
        'notion_token': 'legacy_notion_token_999',
        'theme_mode': 'dark', // Preferencia no sensible que debe permanecer
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('steam_api_key'), equals('legacy_steam_key_777'));
      expect(prefs.getString('rawg_key'), equals('legacy_rawg_key_888'));
      expect(prefs.getString('notion_token'), equals('legacy_notion_token_999'));

      // Ejecutar migración
      await secureStorage.migrateFromSharedPreferences(prefsInstance: prefs);

      // Verificar que los datos ahora residen en SecureStorage
      expect(await secureStorage.getSteamApiKey(), equals('legacy_steam_key_777'));
      expect(await secureStorage.getRawgKey(), equals('legacy_rawg_key_888'));
      expect(await secureStorage.getNotionToken(), equals('legacy_notion_token_999'));

      // Verificar que fueron removidos de SharedPreferences
      expect(prefs.containsKey('steam_api_key'), isFalse);
      expect(prefs.containsKey('rawg_key'), isFalse);
      expect(prefs.containsKey('notion_token'), isFalse);

      // Verificar que preferencias no sensibles se preservaron
      expect(prefs.getString('theme_mode'), equals('dark'));
      expect(prefs.getBool(SecureStorageService.keyMigrationCompleted), isTrue);
    });

    test('Migración soporta clave legada rawg_api_key', () async {
      SharedPreferences.setMockInitialValues({
        'rawg_api_key': 'legacy_rawg_api_key_custom',
      });

      final prefs = await SharedPreferences.getInstance();
      await secureStorage.migrateFromSharedPreferences(prefsInstance: prefs);

      expect(await secureStorage.getRawgKey(), equals('legacy_rawg_api_key_custom'));
      expect(prefs.containsKey('rawg_api_key'), isFalse);
    });

    test('Migración es idempotente y no sobrescribe credenciales existentes en SecureStorage', () async {
      await secureStorage.setSteamApiKey('NEW_SECURE_KEY');

      SharedPreferences.setMockInitialValues({
        'steam_api_key': 'OLD_UNENCRYPTED_KEY',
      });

      final prefs = await SharedPreferences.getInstance();
      await secureStorage.migrateFromSharedPreferences(prefsInstance: prefs);

      // Debe preservar la clave existente en SecureStorage y purgar la de SharedPreferences
      expect(await secureStorage.getSteamApiKey(), equals('NEW_SECURE_KEY'));
      expect(prefs.containsKey('steam_api_key'), isFalse);
    });
  });
}
