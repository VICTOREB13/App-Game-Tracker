# 📋 Checklist de Tareas Atómicas de Implementación (v3.1.0)

**Proyecto:** App Game Tracker  
**Versión Objetivo:** v3.1.0  
**Estado:** Completado (Quality Gate APROBADO - Release v3.1.0 Certificado)  

---

## 🛡️ Fase 1: Seguridad Crítica, Credenciales y Hardening CI/CD

- [x] **[TASK-OPS-01] Remoción y Blindaje del Keystore de Firma en Git**
  - **Rol:** `DevOps-Engineer`
  - **Descripción:** Eliminar `frontend/assets/keystore/release.keystore` del control de versiones git, purgar el historial si aplica, corregir `.gitignore` (línea 43) para bloquear `*.keystore` y `*.jks`, y documentar la inyección del keystore vía secreto Base64 en CI/CD.
  - **Dependencias:** Ninguna
  - **Verificación:** `git status --ignored` confirma que ningún keystore es rastreado; `git check-ignore frontend/assets/keystore/release.keystore` retorna éxito.

- [x] **[TASK-BE-01] Implementación de Almacenamiento Seguro con `flutter_secure_storage`**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Añadir dependencia `flutter_secure_storage: ^9.2.2` a `pubspec.yaml`, crear `SecureStorageService` para guardar de forma cifrada las claves de Steam (`steam_api_key`), RAWG (`rawg_key`) y Notion (`notion_token`), y migrar automáticamente claves existentes desde `SharedPreferences` al primer inicio.
  - **Dependencias:** Ninguna
  - **Verificación:** Pruebas unitarias de `SecureStorageService` verificando lectura/escritura cifrada y ausencia de claves sensibles en `SharedPreferences`.

- [x] **[TASK-QA-01] Configuración de Linter Estricto `analysis_options.yaml`**
  - **Rol:** `Systems-Auditor`
  - **Descripción:** Crear `frontend/analysis_options.yaml` referenciando `package:flutter_lints/flutter.yaml` con reglas estrictas (`prefer_const_constructors`, `unawaited_futures`, `avoid_unnecessary_containers`, `close_sinks`, `cancel_subscriptions`).
  - **Dependencias:** Ninguna
  - **Verificación:** `flutter analyze` reconoce y ejecuta el conjunto completo de reglas del linter.

- [x] **[TASK-OPS-02] Creación del Pipeline de Quality Gate en CI/CD (`ci.yml`)**
  - **Rol:** `DevOps-Engineer`
  - **Descripción:** Crear `.github/workflows/ci.yml` configurado para ejecutarse en cada `push` y `pull_request` sobre ramas principales (`main`, `master`), ejecutando pasos obligatorios de `flutter analyze --fatal-infos` y `flutter test --coverage`.
  - **Dependencias:** `[TASK-QA-01]`
  - **Verificación:** Pipeline de GitHub Actions ejecutándose y bloqueando fusiones en caso de fallos de linter o tests rotos.

---

## ⚡ Fase 2: Concurrencia SQLite, Persistencia y Resiliencia de Red

- [x] **[TASK-BE-02] Protección contra Condiciones de Carrera en `DatabaseService.database`**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Modificar el getter `database` en `DatabaseService` utilizando memoización mediante variable `Future<Database>? _initFuture` para prevenir invocaciones simultáneas duplicadas a `_initDatabase()`.
  - **Dependencias:** Ninguna
  - **Verificación:** Prueba de estrés unitaria lanzando 50 llamadas asíncronas simultáneas a `DatabaseService.instance.database` confirmando que todas retornan la misma instancia sin arrojar `database is locked`.

- [x] **[TASK-BE-03] Configuración de WAL Mode, Pragmas de Integridad e Índices B-Tree**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Añadir callback `onConfigure` en `DatabaseService.openDatabase` con `PRAGMA journal_mode = WAL;`, `foreign_keys = ON;` y `synchronous = NORMAL;`. Crear índices optimizados: `idx_games_title_nocase` (`title COLLATE NOCASE`), `idx_games_updated_at` (`updated_at DESC`), `idx_games_hours_played`, `idx_games_rating` y `idx_games_status_updated`. Añadir estructura de migraciones `onUpgrade`.
  - **Dependencias:** `[TASK-BE-02]`
  - **Verificación:** Consulta `PRAGMA journal_mode` retornando `wal` y consultas `EXPLAIN QUERY PLAN` confirmando uso de índices B-Tree para ordenamientos.

- [x] **[TASK-BE-04] Persistencia Transaccional por Lotes (`batchUpsertGames`)**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Implementar método `batchUpsertGames(List<Game> games)` en `DatabaseService` encapsulado en una transacción atómica `db.transaction(...)` con `txn.batch()`.
  - **Dependencias:** `[TASK-BE-03]`
  - **Verificación:** Prueba unitaria insertando 500 registros en SQLite en menos de 200 ms dentro de una sola transacción.

- [x] **[TASK-BE-05] Desacoplamiento y Refactorización de Sincronización de Steam (`SteamService`)**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Refactorizar `SteamService.syncWithDatabase` en dos fases: Fase 1 (obtención e inserción en lote inmediata de datos de Steam vía `batchUpsertGames`) y Fase 2 (cola asíncrona de enriquecimiento para HLTB/Wikipedia/RAWG con pool de 2 workers y delay de 300 ms). Emitir progreso continuo mediante `Stream<SyncProgress>`.
  - **Dependencias:** `[TASK-BE-04]`
  - **Verificación:** Sincronización de 200 títulos de Steam completando la fase core en < 1 segundo y enriqueciendo metadatos sin disparar errores HTTP 429.

- [x] **[TASK-BE-06] Infraestructura `ResilientHttpClient` y Codificación Segura de URLs**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Crear cliente HTTP resiliente con pool persistente de conexiones, timeouts configurables y reintentos con retroceso exponencial ante errores 429/500. Reemplazar interpolación de strings en `Uri.parse()` por `Uri.https()` con mapas de parámetros. Proteger `HltbService._ensureAuthToken()` con mutex de concurrencia.
  - **Dependencias:** Ninguna
  - **Verificación:** Pruebas unitarias simulando respuestas HTTP 429 y 503 con `MockClient` verificando reintentos con backoff.

- [x] **[TASK-BE-07] Corrección de `BackupService` para Scoped Storage y Rutas Multiplataforma**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Eliminar rutas fijas `/storage/emulated/0/Download` y `$userProfile\Downloads`. Implementar resolución mediante `path_provider` y `file_picker` para exportar e importar respaldos de forma segura en Android 10+ y Windows Desktop.
  - **Dependencias:** Ninguna
  - **Verificación:** Exportación e importación de archivo JSON de respaldo ejecutada con éxito en entornos Android y Windows.

- [x] **[TASK-BE-08] Perfeccionamiento del Patrón Sentinel y Preservación de Fechas en `Game`**
  - **Rol:** `Backend-Architect`
  - **Descripción:** Aplicar `_sentinel` a todos los parámetros opcionales en `Game.copyWith` (incluyendo `hoursPlayed` y `genres`) para permitir su reseteo a `null`. Modificar `toSqliteMap()` para respetar `updatedAt` existente en lugar de sobrescribirlo incondicionalmente con `DateTime.now()`.
  - **Dependencias:** Ninguna
  - **Verificación:** Pruebas unitarias en `game_model_test.dart` verificando reseteo a null con `copyWith(hoursPlayed: null)` y preservación de fechas históricas.

---

## 🎨 Fase 3: Optimización 60 FPS, Memoria y Modularización UI

- [x] **[TASK-FE-01] Optimización de I/O y Memoria en `AppCoverImage`**
  - **Rol:** `Frontend-UI`
  - **Descripción:** Eliminar la llamada síncrona `File.existsSync()` del método `build()`. Configurar `memCacheWidth: 400` y `memCacheHeight: 600` en `CachedNetworkImage` y `cacheWidth: 400` en `Image.file` para evitar desbordamientos de VRAM en listas y cuadrículas.
  - **Dependencias:** Ninguna
  - **Verificación:** Medición de FPS en Flutter DevTools durante desplazamiento rápido de catálogo manteniendo 60 FPS estables y memoria RAM controlada.

- [x] **[TASK-FE-02] Conexión de Filtros de UI con Motor SQL en `DashboardScreen`**
  - **Rol:** `Frontend-UI` / `Backend-Architect`
  - **Descripción:** Refactorizar `DashboardScreen` para delegar el filtrado por estado, plataforma, búsqueda de texto y ordenamiento directamente a las cláusulas `WHERE`, `ORDER BY` y `LIMIT` de `DatabaseService`, precalculando opciones de filtro en memoria solo tras cambios en la base de datos.
  - **Dependencias:** `[TASK-BE-03]`
  - **Verificación:** Búsquedas y cambios de filtro ejecutándose en < 10 ms sobre bases de datos de más de 1,000 juegos.

- [x] **[TASK-FE-03] Modularización de la Pantalla Monolítica `DashboardScreen` (2,686 líneas)**
  - **Rol:** `Frontend-UI`
  - **Descripción:** Descomponer `frontend/lib/screens/dashboard.dart` extrayendo los siguientes widgets modulares a `frontend/lib/widgets/dashboard/`:
    - `game_card_grid.dart`
    - `game_card_list.dart`
    - `hero_spotlight_card.dart` (con `RepaintBoundary` en el pulso continuo)
    - `pagination_control_bar.dart`
    - `steam_sync_dialog.dart`
  - **Dependencias:** `[TASK-FE-01]`, `[TASK-FE-02]`
  - **Verificación:** `dashboard.dart` reducido a menos de 450 líneas; tests de widgets independientes para cada componente visual extraído.

- [x] **[TASK-FE-04] Prevención de Fugas de Memoria en Diálogos y Limpieza de Código Muerto**
  - **Rol:** `Frontend-UI` / `Systems-Auditor`
  - **Descripción:** Modularizar diálogos con `TextEditingController`s en `StatefulWidget`s con ciclo de vida `dispose()` formal (`search_screen.dart`, `analytics_screen.dart`, `settings_screen.dart`). Limpiar o aislar los archivos legados de Notion (`notion_service.dart`, `notion_parser.dart`, `setup_screen.dart`).
  - **Dependencias:** Ninguna
  - **Verificación:** Inspección en Flutter DevTools Memory Profiler confirmando que no hay instancias retenidas de `TextEditingController` tras cerrar diálogos.

---

## 🧪 Fase 4: Cobertura de Pruebas, Verificación y Quality Gate Final

- [x] **[TASK-QA-02] Suite de Pruebas Unitarias de Red Deterministas (Mocks HTTP)**
  - **Rol:** `Systems-Auditor`
  - **Descripción:** Refactorizar `test/hltb_service_test.dart` y `test/metadata_service_test.dart`, y crear `test/steam_service_test.dart` utilizando `MockClient` para simular respuestas exitosas, errores 429, 500 y timeouts sin requerir conexión a internet.
  - **Dependencias:** `[TASK-BE-06]`
  - **Verificación:** `flutter test test/*_service_test.dart` ejecutándose en modo offline al 100% en < 2 segundos.

- [x] **[TASK-QA-03] Suite de Pruebas Unitarias para SQLite y Persistencia Local**
  - **Rol:** `Systems-Auditor` / `Backend-Architect`
  - **Descripción:** Crear `test/database_service_test.dart` y `test/backup_service_test.dart` utilizando base de datos en memoria (`sqflite_common_ffi`) para validar CRUD, Sentinel, ordenamientos NOCASE, `batchUpsertGames`, transacciones y exportación/importación JSON.
  - **Dependencias:** `[TASK-BE-03]`, `[TASK-BE-04]`, `[TASK-BE-07]`, `[TASK-BE-08]`
  - **Verificación:** 100% de aserciones pasando en la suite de base de datos.

- [x] **[TASK-QA-04] Suite de Pruebas de Widgets y UI**
  - **Rol:** `Systems-Auditor` / `Frontend-UI`
  - **Descripción:** Crear pruebas de widgets en `test/widgets/` para validar el renderizado de `AppCoverImage`, `GameCardGrid`, `FilterModalSheet` y la navegación del `DashboardScreen`.
  - **Dependencias:** `[TASK-FE-01]`, `[TASK-FE-03]`
  - **Verificación:** `flutter test test/widgets/` pasando al 100%.

- [x] **[TASK-QA-05] Auditoría de Quality Gate y Certificación de Release v3.1.0**
  - **Rol:** `Systems-Auditor` / `DevOps-Engineer`
  - **Descripción:** Ejecutar análisis completo de linter (`flutter analyze --fatal-infos`) y suite de pruebas con reporte de cobertura (`flutter test --coverage`), consolidando el reporte formal de Quality Gate en `artifacts/audit_reports/audit_report.md` con veredicto `Status: PASS`.
  - **Dependencias:** Todas las tareas anteriores completadas
  - **Verificación:** Reporte formal de auditoría con `Status: PASS` autorizando a DevOps para la compilación y publicación de binarios v3.1.0.
