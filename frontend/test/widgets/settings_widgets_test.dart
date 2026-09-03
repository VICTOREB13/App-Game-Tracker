import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tracker_app/views/widgets/settings/backup_settings_card.dart';
import 'package:tracker_app/views/widgets/settings/branding_footer.dart';
import 'package:tracker_app/views/widgets/settings/database_settings_card.dart';
import 'package:tracker_app/views/widgets/settings/hltb_settings_card.dart';
import 'package:tracker_app/views/widgets/settings/rawg_settings_card.dart';
import 'package:tracker_app/views/widgets/settings/settings_section_header.dart';
import 'package:tracker_app/views/widgets/settings/steam_settings_card.dart';
import 'package:tracker_app/views/widgets/settings/sync_summary_dialog.dart';
import 'package:tracker_app/views/widgets/settings/theme_settings_card.dart';

void main() {
  group('Settings Widgets Modular Suite', () {
    testWidgets('SettingsSectionHeader renderiza el título correctamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsSectionHeader('Sección de Prueba'),
          ),
        ),
      );

      expect(find.text('Sección de Prueba'), findsOneWidget);
    });

    testWidgets('ThemeSettingsCard renderiza opciones de tema visual',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThemeSettingsCard(),
          ),
        ),
      );

      expect(find.text('Tema Visual'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('DatabaseSettingsCard renderiza métricas y responde a botones',
        (WidgetTester tester) async {
      bool refreshCalled = false;
      bool optimizeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseSettingsCard(
              gameCount: 42,
              totalHours: 128.5,
              dbPath: 'C:\\app\\games.db',
              onRefresh: () => refreshCalled = true,
              onOptimize: () => optimizeCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Motor SQLite Activo (Local-First)'), findsOneWidget);
      expect(find.text('Biblioteca: 42 videojuegos registrados • 128.5 horas registradas'), findsOneWidget);
      expect(find.text('Ruta: C:\\app\\games.db'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(refreshCalled, isTrue);

      await tester.tap(find.text('Optimizar Base de Datos (Vacuum)'));
      expect(optimizeCalled, isTrue);
    });

    testWidgets('SteamSettingsCard renderiza inputs y responde a acciones',
        (WidgetTester tester) async {
      final keyCtrl = TextEditingController(text: 'ABC123KEY');
      final idCtrl = TextEditingController(text: '76561198000000000');
      bool saveCalled = false;
      bool testCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SteamSettingsCard(
              steamKeyController: keyCtrl,
              steamIdController: idCtrl,
              isTestingSteam: false,
              isSyncingSteam: false,
              onSave: () => saveCalled = true,
              onResolveVanity: () {},
              onTestConnection: () => testCalled = true,
              onSyncNow: () {},
            ),
          ),
        ),
      );

      expect(find.text('Steam Web API Key'), findsOneWidget);
      expect(find.text('SteamID64 o Vanity URL'), findsOneWidget);

      await tester.tap(find.byTooltip('Guardar clave'));
      expect(saveCalled, isTrue);

      await tester.tap(find.text('Probar Conexión'));
      expect(testCalled, isTrue);
    });

    testWidgets('RawgSettingsCard renderiza input y botón de sincronización',
        (WidgetTester tester) async {
      final ctrl = TextEditingController(text: 'RAWG_API_KEY');
      bool syncCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawgSettingsCard(
              rawgKeyController: ctrl,
              isSyncingMetadata: false,
              onSave: () {},
              onSyncAllMetadata: () => syncCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('RAWG API Key'), findsOneWidget);
      await tester.tap(find.text('Sincronizar Géneros, Portadas y Wikipedia'));
      expect(syncCalled, isTrue);
    });

    testWidgets('HltbSettingsCard renderiza información y responde a sincronizar',
        (WidgetTester tester) async {
      bool hltbCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HltbSettingsCard(
              isSyncingHltb: false,
              onSyncAllHltb: () => hltbCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Sincronización HowLongToBeat'), findsOneWidget);
      await tester.tap(find.text('Buscar Duraciones HLTB'));
      expect(hltbCalled, isTrue);
    });

    testWidgets('BackupSettingsCard responde a exportar e importar',
        (WidgetTester tester) async {
      bool exportCalled = false;
      bool importCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackupSettingsCard(
              onExportBackup: () => exportCalled = true,
              onImportBackup: () => importCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Exportar JSON'));
      expect(exportCalled, isTrue);

      await tester.tap(find.text('Importar JSON'));
      expect(importCalled, isTrue);
    });

    testWidgets('BrandingFooter renderiza monograma y créditos',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandingFooter(appVersion: 'v3.2.0'),
          ),
        ),
      );

      expect(find.text('VE'), findsOneWidget);
      expect(find.text('Victor '), findsOneWidget);
      expect(find.text('Engineer'), findsOneWidget);
      expect(find.text('Gaming Tracker App • v3.2.0'), findsOneWidget);
      expect(find.text('https://victorengineer.fyi'), findsOneWidget);
    });

    testWidgets('SyncSummaryDialog renderiza título y detalles en AlertDialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncSummaryDialog(
              title: 'Resumen de Prueba',
              message: 'Operación completada con éxito',
              details: [
                '🎮 Juegos encontrados: 5',
                '🔄 Actualizados: 2',
              ],
            ),
          ),
        ),
      );

      expect(find.text('Resumen de Prueba'), findsOneWidget);
      expect(find.text('Operación completada con éxito'), findsOneWidget);
      expect(find.text('🎮 Juegos encontrados: 5'), findsOneWidget);
      expect(find.text('🔄 Actualizados: 2'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
    });
  });
}
