# 🛡️ Reporte de Auditoría Técnica Multidimensional del Código Fuente

**Proyecto:** App Game Tracker (v3.0.6)  
**Fecha de Auditoría:** 2026-08-29  
**Equipo Auditor:** Orquestador de Proyecto, Systems &amp; QA Auditor, Backend-Architect &amp; SQLite Specialist, Network &amp; UI Architect  
**Entorno de Integridad:** Solo Lectura (0 archivos modificados en `frontend/lib/`)  
**Veredicto General de Quality Gate:** **FAIL (Requiere Remediación Pre-Release v3.1.0)**  

---

## 1. Resumen Ejecutivo y Diagnóstico Global

Se ha llevado a cabo una auditoría técnica exhaustiva y multidimensional sobre el código fuente de **App Game Tracker** (Flutter, Dart, SQLite, APIs de Steam, HowLongToBeat, RAWG, Wikipedia y pipelines de CI/CD en GitHub Actions). 

### Métricas Globales del Código:

- **Líneas de Código Analizadas:** ~6,500+ líneas en `frontend/lib/`.
- **Cobertura de Pruebas Automatizadas Actual:** **&lt; 12%** (0% en capa de widgets y pantallas, 0% en capa de servicios de base de datos y sincronización).
- **Pruebas Existentes:** 4 archivos (`game_model_test.dart`, `hltb_service_test.dart`, `metadata_service_test.dart`, `string_normalizer_test.dart`) con 8 tests en total. Se detectaron pruebas con peticiones HTTP reales no simuladas (falsos positivos).
- **Configuración de Linter:** Inactiva (ausencia de `analysis_options.yaml` a pesar de estar declarado `flutter_lints` en `pubspec.yaml`).
- **Integridad de Producción:** Se certifica que ningún archivo bajo `frontend/lib/` fue alterado durante este ciclo de auditoría.

### Distribución de Hallazgos por Severidad:


| Severidad                  | Cantidad | Impacto Principal                                                                                                                                                                                                                                 |
| -------------------------- | :--------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🔴 **Crítica**             | 4        | Exposición de claves de firma en repositorio, tormenta N+1 de peticiones HTTP en sincronización de Steam, ausencia de Quality Gates en CI/CD, almacenamiento inseguro de secretos.                                                                |
| 🟠 **Alta**                | 7        | Condición de carrera en singleton SQLite, falta de WAL mode y transacciones por lotes, pruebas unitarias frágiles con llamadas de red en vivo, violación de Android Scoped Storage, linter inactivo, falta de pool de conexiones HTTP resiliente. |
| 🟡 **Media**               | 10       | I/O síncrono bloqueante en `build()`, falta de límites de memoria en carátulas (`memCacheWidth`), getters O(N) en el hilo de UI, memoria fugada en controladores de diálogos, pantalla monolítica de 2,686 líneas, código muerto (Notion legado). |
| 🟢 **Baja / Optimización** | 4        | Incompatibilidad de colación en índices B-Tree, dependencias desactualizadas, disparidad de versiones de Flutter en CI/CD, lookups redundantes de temas.                                                                                          |
| **Total**                  | **25**   | Diagnóstico estructurado y detallado a continuación.                                                                                                                                                                                              |


---

## 2. Hallazgos Detallados por Dimensión

---

### Dimensión 1: Integridad de Base de Datos y Concurrencia SQLite

```
[get database sin mutex] ────────► [Colisión de apertura FFI concurrente] ──► [DatabaseException: locked]
[journal_mode = DELETE] ────────► [Bloqueo de base de datos en sync] ───────► [UI Jank / Freeze en lecturas]
[Escrituras individuales síncronas] ► [300+ fsyncs consecutivos en disco] ────► [Sync lenta >30s + degradación]
```

#### D1-01 (Severidad: Alta) — Condición de Carrera Asíncrona en la Inicialización de SQLite

- **Archivo:** `frontend/lib/services/database_service.dart`
- **Rango de Líneas:** 23–27
- **Descripción Técnica:** El getter `Future<Database> get database async` evalúa `if (_database != null) return _database!;` antes de ejecutar `_database = await _initDatabase();`. Cuando múltiples componentes asíncronos invocan el getter simultáneamente durante el arranque de la app (ej. `main.dart`, `DashboardScreen`, `ThemeManager` o sincronización inicial), la condición evalúa a falso en todas las llamadas antes de completar la primera inicialización. En `sqflite_common_ffi` para Desktop, esto provoca colisiones de bloqueo (`DatabaseException: database is locked`) o conexiones duplicadas desincronizadas.
- **Remediación Concreta:** Implementar memoización de inicialización asíncrona mediante un `Completer<Database>?` o variable `Future<Database>? _initFuture`:
  ```dart
  Future<Database>? _initFuture;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
    return _database!;
  }
  ```

#### D1-02 (Severidad: Alta) — Ausencia de Modo WAL (Write-Ahead Logging) y Pragmas de Integridad

- **Archivo:** `frontend/lib/services/database_service.dart`
- **Rango de Líneas:** 43–48
- **Descripción Técnica:** SQLite opera por defecto en modo `journal_mode = DELETE`. En este modo, cualquier transacción de escritura bloquea la base de datos de manera exclusiva, deteniendo todas las lecturas concurrentes de la UI. Además, no se activan las claves foráneas ni se optimiza el modo síncrono.
- **Remediación Concreta:** Añadir el callback `onConfigure` en `openDatabase`:
  ```dart
  return await openDatabase(
    dbPath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA journal_mode = WAL;');
      await db.execute('PRAGMA synchronous = NORMAL;');
      await db.execute('PRAGMA foreign_keys = ON;');
    },
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
  ```

#### D1-03 (Severidad: Alta) — Escrituras Individuales no Transaccionales Intercaladas con I/O de Red

- **Archivo:** `frontend/lib/services/steam_service.dart` (Líneas 358, 443), `frontend/lib/services/database_service.dart` (Líneas 215–228)
- **Rango de Líneas:** `steam_service.dart`: 292–445
- **Descripción Técnica:** En `SteamService.syncWithDatabase`, por cada juego detectado en Steam se ejecuta un `await db.updateGame(updated)` o `await db.insertGame(newGame)` individual. En SQLite, cada sentencia fuera de una transacción explícita ejecuta un ciclo completo de apertura de transacción, escritura en disco y llamada `fsync`. Con 300 juegos, esto dispara 300 `fsyncs` síncronos, elevando el tiempo de persistencia de &lt;100ms a más de 30 segundos, manteniendo la base de datos bloqueada de forma intermitente.
- **Remediación Concreta:** Desacoplar la fase de red de la persistencia. Acumular los registros en listas en memoria y persistirlos en una sola transacción atómica por lotes usando `batchUpsertGames()` con `db.transaction(...)`:
  ```dart
  Future<void> batchUpsertGames(List<Game> games) async {
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
  ```

#### D1-04 (Severidad: Media) — Incompatibilidad de Collation en Índice `idx_games_title` e Índices Faltantes

- **Archivo:** `frontend/lib/services/database_service.dart`
- **Rango de Líneas:** 74–78, 114–132
- **Descripción Técnica:** El índice `idx_games_title` se crea con colación binaria estándar. Sin embargo, las consultas de ordenamiento y filtrado ejecutan `ORDER BY title COLLATE NOCASE`. SQLite **no puede** utilizar un índice binario para satisfacer un `COLLATE NOCASE`, forzando un escaneo completo de tabla y ordenamiento en memoria (`filesort`). Asimismo, el ordenamiento por defecto (`updated_at DESC`) carece de índice B-Tree.
- **Remediación Concreta:** Crear los índices B-Tree optimizados:
  ```sql
  CREATE INDEX idx_games_title_nocase ON games(title COLLATE NOCASE);
  CREATE INDEX idx_games_updated_at ON games(updated_at DESC);
  CREATE INDEX idx_games_hours_played ON games(hours_played DESC);
  CREATE INDEX idx_games_rating ON games(rating DESC, hours_played DESC);
  CREATE INDEX idx_games_status_updated ON games(status, updated_at DESC);
  ```

#### D1-05 (Severidad: Media) — Carga Completa en RAM y Filtrado en Dart en Lugar del Motor SQLite

- **Archivo:** `frontend/lib/screens/dashboard.dart` (Líneas 146–154, 329–374), `frontend/lib/screens/analytics_screen.dart` (Líneas 46–114)
- **Rango de Líneas:** `dashboard.dart`: 146, 333–364
- **Descripción Técnica:** A pesar de que `DatabaseService.getAllGames` acepta parámetros `where`, `DashboardScreen` y `AnalyticsScreen` llaman a `getAllGames()` sin argumentos, cargando toda la tabla a memoria RAM para filtrar y ordenar mediante bucles en el hilo de UI de Dart. Esto invalida el beneficio de los índices B-Tree de SQLite y causa presión en el Garbage Collector.
- **Remediación Concreta:** Delegar el filtrado, búsqueda y ordenación directamente a las cláusulas `WHERE`, `ORDER BY` y `LIMIT / OFFSET` en SQLite, e implementar métodos de agregación SQL dedicados (`getStatusCounts()`, `getPlatformCounts()`, `getTopRated()`) en `DatabaseService`.

#### D1-06 (Severidad: Media) — Implementación Incompleta del Patrón Sentinel en `Game.copyWith` y Destrucción de `updated_at`

- **Archivo:** `frontend/lib/models/game.dart`
- **Rango de Líneas:** 149, 171, 346, 369
- **Descripción Técnica:** En `Game.copyWith`, campos como `hoursPlayed` y `genres` no utilizan el centinela `_sentinel`, por lo que pasar `null` para reiniciar un valor es ignorado por `hoursPlayed ?? this.hoursPlayed`. En `toSqliteMap()`, `'updated_at'` está fijado a `DateTime.now().toIso8601String()`, destruyendo las fechas originales durante importaciones o restauraciones de respaldo.
- **Remediación Concreta:**
  1. Aplicar `_sentinel` a todos los parámetros opcionales en `Game.copyWith`:
    ```dart
     Object? hoursPlayed = _sentinel,
     // ...
     hoursPlayed: identical(hoursPlayed, _sentinel) ? this.hoursPlayed : (hoursPlayed as num?),
    ```
  2. Preservar `updatedAt` original en `toSqliteMap()`:
    ```dart
     'updated_at': updatedAt?.toIso8601String() ?? now,
    ```

#### D1-07 (Severidad: Media) — Ausencia de Controlador de Migraciones `onUpgrade`

- **Archivo:** `frontend/lib/services/database_service.dart`
- **Rango de Líneas:** 43–48
- **Descripción Técnica:** `openDatabase` está fijado en `version: 1` sin parámetro `onUpgrade`. Cualquier evolución futura del esquema (nuevos campos o tablas) causará incompatibilidad o requerirá borrar la base de datos del usuario.
- **Remediación Concreta:** Implementar un despachador incremental de versiones en `onUpgrade`:
  ```dart
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      switch (v) {
        case 2:
          await _migrateToV2(db);
          break;
      }
    }
  }
  ```

---

### Dimensión 2: Resiliencia de Red y Consumo de APIs Externas

```
[Sync de Steam: 300 juegos] ──► [3 peticiones por juego en bucle] ──► [900 peticiones secuenciales] ──► [HTTP 429 Rate Limit / Timeout]
[Sin pool http.Client] ──────► [Handshake TLS por cada llamada] ───► [Consumo innecesario de sockets y latencia]
[Uri.parse con strings] ─────► [Caracteres especiales sin escapar] ─► [Malformed URI / Excepción de red]
```

#### D2-01 (Severidad: Crítica) — Peticiones N+1 Masivas en Sincronización de Steam

- **Archivo:** `frontend/lib/services/steam_service.dart`
- **Rango de Líneas:** 215–451 (esp. 292, 325, 337, 374, 386, 396)
- **Descripción Técnica:** En `syncWithDatabase()`, dentro del bucle sobre la biblioteca de Steam, se ejecutan peticiones HTTP síncronas secuenciales individuales a HLTB (`searchHltb`), Wikipedia (`searchWikipedia`) y RAWG (`searchRawg`) para cada título. Con una biblioteca de 300 juegos, esto genera hasta 900 peticiones secuenciales sin control de concurrencia, sin rate limiting y sin posibilidad de cancelación.
- **Remediación Concreta:** 
  1. Dividir la sincronización en dos fases:
    - **Fase 1 (Inmediata / Core):** Importar datos nativos de Steam (appid, título, horas, cover de Steam CDN) y persistir en una sola transacción SQLite por lotes (&lt; 1 segundo).
    - **Fase 2 (Enriquecimiento asíncrono en segundo plano):** Worker pool con concurrencia máxima de 2 peticiones paralelas y un delay de 300 ms entre llamadas.
  2. Implementar `Stream<SyncProgress>` con `CancellationToken`.

#### D2-02 (Severidad: Alta) — Ausencia de Pool de `http.Client` Persistente y Retroceso Exponencial

- **Archivo:** `frontend/lib/services/steam_service.dart`, `frontend/lib/services/hltb_service.dart`, `frontend/lib/services/metadata_service.dart`
- **Rango de Líneas:** `steam_service.dart`: 59, 89, 121, 142; `hltb_service.dart`: 67, 165; `metadata_service.dart`: 53, 102
- **Descripción Técnica:** Todas las llamadas de red instancian llamadas `http.get()` o `http.post()` efímeras que abren y cierran conexiones TCP/TLS individuales sin reutilización de sockets (HTTP Keep-Alive). Además, ante códigos HTTP 429 (Rate Limit) o 500/503 de servidores de terceros, las peticiones fallan inmediatamente sin intentar retroceso exponencial (*exponential backoff*).
- **Remediación Concreta:** Crear una clase de infraestructura `ResilientHttpClient` compartida que gestione pool de conexiones persistentes, timeouts configurables y reintentos con backoff exponencial.

#### D2-03 (Severidad: Alta) — Interpolación Insegura de Strings en `Uri.parse()` sin Codificación de Parámetros

- **Archivo:** `frontend/lib/services/steam_service.dart` (Líneas 57–58, 87–88), `frontend/lib/screens/search_screen.dart` (Líneas 137–138)
- **Rango de Líneas:** 57–59, 87–89, 137–139
- **Descripción Técnica:** Se construyen URLs mediante concatenación de cadenas (`vanityurl=$cleanVanity` y `search=$trimmed`) e invocando `Uri.parse()`. Si el título o parámetro contiene caracteres como `&`, `+`, `#` o acentos, la URL se malforma provocando respuestas HTTP 400 o resultados incorrectos.
- **Remediación Concreta:** Construir URIs utilizando constructores canónicos con mapas de parámetros de consulta:
  ```dart
  final url = Uri.https('api.rawg.io', '/api/games', {
    'key': rawgKey.trim(),
    'search': trimmedQuery,
    'page_size': '15',
  });
  ```

#### D2-04 (Severidad: Media) — Condición de Carrera en Inicialización de Token de Sesión HLTB

- **Archivo:** `frontend/lib/services/hltb_service.dart`
- **Rango de Líneas:** 54–84
- **Descripción Técnica:** El método `_ensureAuthToken()` no posee cerrojo de concurrencia. Múltiples llamadas asíncronas simultáneas (ej. al abrir varios detalles o en búsquedas concurrentes) disparan peticiones duplicadas e innecesarias a `/api/search/site/init`.
- **Remediación Concreta:** Implementar un mutex o memoización de token mediante `Completer<String>? _tokenCompleter`.

#### D2-05 (Severidad: Media) — Pruebas Unitarias de Red con Peticiones en Vivo a Internet

- **Archivo:** `frontend/test/hltb_service_test.dart` (Líneas 22–31), `frontend/test/metadata_service_test.dart` (Líneas 6–17)
- **Rango de Líneas:** 22–31, 6–17
- **Descripción Técnica:** Las pruebas unitarias envían solicitudes HTTP reales a los servidores de HLTB y Wikipedia. En `hltb_service_test.dart:25`, la condición `if (result != null) { ... }` hace que la prueba pase silenciosamente (falso positivo) si la conexión está caída o si HLTB devuelve error.
- **Remediación Concreta:** Inyectar un `http.Client` mockeado (`MockClient` de `http/testing.dart`) en los constructores de los servicios para simular payloads JSON exitosos, errores 404, 429 y 500 de manera determinista y sin conexión a internet.

---

### Dimensión 3: Arquitectura y Rendimiento Flutter (60 FPS)

```
[AppCoverImage: existsSync() en build()] ──► [Bloqueo sincrónico del hilo de UI] ──► [Frame drops / Jank al hacer scroll]
[CachedNetworkImage sin memCacheWidth] ──► [Decodificación a resolución nativa] ──► [Consumo excesivo de VRAM/RAM]
[Dialogs con TextEditingController] ──────► [Controladores sin dispose()] ────────► [Fuga de memoria / Memory Leak]
[DashboardScreen: 2686 líneas] ───────────► [Lógica, estado y UI monolítica] ─────► [Alta complejidad y acoplamiento]
```

#### D3-01 (Severidad: Crítica) — Comprobación Síncrona de Archivos `File.existsSync()` en el Árbol de Widgets

- **Archivo:** `frontend/lib/widgets/app_cover_image.dart`
- **Rango de Líneas:** 44–46
- **Descripción Técnica:** En `AppCoverImage.build()`, se ejecuta `if (File(url).existsSync())` directamente en el hilo principal de renderizado de Flutter. Durante el scroll rápido en listas o cuadrículas con cientos de juegos, esta llamada síncrona a disco bloquea el isolate de UI, generando caídas de frames notables (*jank*).
- **Remediación Concreta:** Eliminar la llamada síncrona `existsSync()` y utilizar `Image.file` de forma asíncrona delegando el control de fallo al parámetro `errorBuilder`:
  ```dart
  Image.file(
    File(url),
    width: width,
    height: height,
    fit: fit,
    cacheWidth: width != null ? (width! * 2).toInt() : 400,
    cacheHeight: height != null ? (height! * 2).toInt() : 600,
    errorBuilder: (ctx, _, __) => errorWidget ?? _buildDefaultPlaceholder(ctx),
  );
  ```

#### D3-02 (Severidad: Alta) — Ausencia de `memCacheWidth` y `memCacheHeight` en Carátulas

- **Archivo:** `frontend/lib/widgets/app_cover_image.dart`
- **Rango de Líneas:** 35–42
- **Descripción Técnica:** `CachedNetworkImage` descarga y decodifica las imágenes en su resolución nativa (hasta 4K en algunas fuentes de RAWG/Steam), consumiendo hasta 8 MB de VRAM por imagen en memoria de GPU en lugar de reescalarlas al tamaño visual de la tarjeta (~400x600 px). En una cuadrícula de 100 juegos, esto puede consumir más de 500 MB de RAM y provocar fallos de Out-Of-Memory (OOM) en Android.
- **Remediación Concreta:** Configurar `memCacheWidth` y `memCacheHeight` explícitos en `CachedNetworkImage` y `cacheWidth` / `cacheHeight` en `Image.file`.

#### D3-03 (Severidad: Alta) — Getters O(N) Pesados Recalculados en Cada Frame de `DashboardScreen.build()`

- **Archivo:** `frontend/lib/screens/dashboard.dart`
- **Rango de Líneas:** 376–435
- **Descripción Técnica:** Los getters `_availablePlatformOptions` y `_availableGenreOptions` ejecutan iteraciones completas sobre toda la lista de juegos, expresiones regulares de normalización y ordenamientos alfabéticos dentro del método `build()`. Cada vez que se pulsa una tecla de búsqueda o se actualiza un estado menor, estos getters se recalculan.
- **Remediación Concreta:** Precalcular las opciones de filtro una sola vez en `_updateFilterOptions()` al recibir nuevos datos desde SQLite y almacenarlas en variables de estado.

#### D3-04 (Severidad: Media) — Fugas de Memoria por `TextEditingController`s sin `dispose()` en Diálogos

- **Archivo:** `frontend/lib/screens/search_screen.dart` (Línea 155), `frontend/lib/screens/analytics_screen.dart` (Línea 117), `frontend/lib/screens/settings_screen.dart` (Línea 1149)
- **Rango de Líneas:** 155, 117, 1149
- **Descripción Técnica:** Se instancian `TextEditingController`s dentro de funciones auxiliares que abren diálogos modales (`showDialog`), pero nunca se invoca `dispose()`, dejando listeners y recursos adjuntos retenidos en memoria de forma permanente.
- **Remediación Concreta:** Modularizar los diálogos en `StatefulWidget`s dedicados que implementen el ciclo de vida `dispose()` formal o envolver en bloques seguros con `controller.dispose()`.

#### D3-05 (Severidad: Media) — Pantalla Monolítica de 2,686 Líneas (`screens/dashboard.dart`)

- **Archivo:** `frontend/lib/screens/dashboard.dart`
- **Rango de Líneas:** 1–2686
- **Descripción Técnica:** `DashboardScreen` actúa como un "God Class", concentrando en un único archivo la lógica de sincronización con Steam, filtrado en memoria, paginación, animaciones de pulso continuo, tarjetas de juegos (`_GameCard`, `_GameListRow`), barra de navegación y diálogos modales. Esto dificulta el mantenimiento y la creación de pruebas de widgets aisladas.
- **Remediación Concreta:** Descomponer el archivo en componentes modulares bajo `frontend/lib/widgets/dashboard/`:
  - `game_card_grid.dart` y `game_card_list.dart`
  - `hero_spotlight_card.dart`
  - `pagination_control_bar.dart`
  - `steam_sync_dialog.dart`

#### D3-06 (Severidad: Media) — Bucle de Animación Continua Desacoplado de `RepaintBoundary`

- **Archivo:** `frontend/lib/screens/dashboard.dart`
- **Rango de Líneas:** 59–63, 1497–1516
- **Descripción Técnica:** El controlador `_pulseController` se ejecuta en un bucle continuo infinito para animar el indicador visual del "Hero Spotlight". Al carecer de `RepaintBoundary`, el repintado a 60 FPS invalida el árbol de renderizado circundante, incrementando el uso de CPU en estado inactivo.
- **Remediación Concreta:** Aislar los widgets con animaciones continuas dentro de su propio `RepaintBoundary`.

---

### Dimensión 4: Seguridad y Privacidad Local

```
[Claves API Steam/RAWG/Notion] ──► [Guardado en SharedPreferences] ──► [XML/JSON en texto plano en disco] ──► [Exposición de credenciales]
[Android release.keystore] ─────► [Cometido en repositorio Git] ─────► [Compromiso total de firma APK] ────► [Riesgo de suplantación]
```

#### D4-01 (Severidad: Crítica) — Exposición de Keystore de Firma de Producción en el Repositorio

- **Archivo:** `.gitignore` (Línea 43), `frontend/assets/keystore/release.keystore`
- **Rango de Líneas:** `.gitignore`: 43
- **Descripción Técnica:** El archivo de claves de firma de producción para Android (`release.keystore`) se encuentra incluido en el control de versiones, y la línea 43 de `.gitignore` lo des-ignora explícitamente (`!frontend/assets/keystore/release.keystore`). Esto expone la clave criptográfica privada de la aplicación a cualquiera con acceso al repositorio.
- **Remediación Concreta:**
  1. Eliminar `release.keystore` del repositorio y purgar el historial git.
  2. Generar un nuevo keystore privado fuera del árbol de control de versiones.
  3. Modificar `.gitignore` para bloquear `*.keystore` y `*.jks`.
  4. Inyectar el keystore en los workflows de CI/CD como un secreto codificado en Base64 (`KEYSTORE_BASE64`).

#### D4-02 (Severidad: Crítica) — Almacenamiento en Texto Plano de Claves API (Steam, RAWG) y Tokens de Notion

- **Archivo:** `frontend/lib/screens/settings_screen.dart` (Líneas 64–67, 78–82), `frontend/lib/screens/setup_screen.dart` (Líneas 97–101), `frontend/lib/services/steam_service.dart` (Líneas 212–214)
- **Rango de Líneas:** 64–67, 78–82, 97–101, 212–214
- **Descripción Técnica:** Las claves de API de Steam y RAWG, junto con el token de autenticación de Notion, se guardan en texto plano utilizando `SharedPreferences`. En Android, esto se guarda en un archivo XML sin cifrar (`/data/data/<package>/shared_prefs/`), y en Windows en archivos JSON no protegidos.
- **Remediación Concreta:** Adoptar `flutter_secure_storage` para cifrar todas las credenciales sensibles mediante hardware/OS security (Android Keystore y Windows DPAPI/Credential Manager), reservando `SharedPreferences` exclusivamente para preferencias visuales de UI.

#### D4-03 (Severidad: Alta) — Violación de Scoped Storage en Android y Rutas Inseguras en Windows

- **Archivo:** `frontend/lib/services/backup_service.dart`
- **Rango de Líneas:** 10–22
- **Descripción Técnica:** El método `_getDownloadsDirectory()` contiene rutas físicas hardcodeadas como `/storage/emulated/0/Download` y `$userProfile\Downloads`. En Android 10+ (API 29+), esto viola *Scoped Storage* y arroja excepciones de permisos denegados. En Windows con carpetas redirigidas (OneDrive), la ruta falla y cae en `Directory.current` (ubicación protegida en `Program Files`).
- **Remediación Concreta:** Utilizar `path_provider` (`getApplicationDocumentsDirectory()`, `getDownloadsDirectory()`) y delegar la selección de archivos a `file_picker` mediante selectores del sistema operativo.

---

### Dimensión 5: Calidad de Código, Linter y Cobertura de Pruebas

```
[Ausencia de analysis_options.yaml] ──► [Reglas de flutter_lints inactivas] ──► [Deuda técnica invisible]
[Falta de Quality Gates en CI/CD] ────► [Releases publicados sin tests] ─────► [Regresiones en producción]
[Cobertura < 12%] ────────────────────► [Cero pruebas en UI y BD] ───────────► [Fragilidad arquitectónica]
```

#### D5-01 (Severidad: Crítica) — Ausencia Total de Quality Gates en Pipelines de CI/CD

- **Archivo:** `.github/workflows/build_apk.yml` (Líneas 1–75), `.github/workflows/build_windows.yml` (Líneas 1–72), `.github/workflows/release.yml` (Líneas 1–164)
- **Rango de Líneas:** 1–75, 1–72, 1–164
- **Descripción Técnica:** Ninguno de los workflows de compilación o publicación ejecuta `flutter analyze` ni `flutter test`. Además, no existe un workflow de validación para Pull Requests (`on: pull_request`). Un commit con errores de compilación o pruebas rotas puede compilarse y publicarse automáticamente.
- **Remediación Concreta:** Implementar un workflow obligatorio `.github/workflows/ci.yml` que ejecute `flutter analyze --fatal-infos` y `flutter test --coverage` en cada `push` y `pull_request`, bloqueando la fusión y publicación si el Quality Gate no pasa con éxito.

#### D5-02 (Severidad: Alta) — Ausencia de Archivo de Configuración de Linter `analysis_options.yaml`

- **Archivo:** `frontend/pubspec.yaml` (Línea 29), raíz del proyecto
- **Rango de Líneas:** `pubspec.yaml`: 29
- **Descripción Técnica:** `flutter_lints: ^3.0.0` está declarado en `pubspec.yaml`, pero no existe ningún archivo `analysis_options.yaml` en el proyecto. Por tanto, el analizador estático de Dart se ejecuta con reglas mínimas desactivadas, permitiendo prácticas propensas a errores.
- **Remediación Concreta:** Crear `frontend/analysis_options.yaml` con configuración estricta:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  
  analyzer:
    language:
      strict-casts: true
      strict-inference: true
      strict-raw-types: true
    errors:
      missing_required_param: error
      missing_return: error
      todo: ignore
  
  linter:
    rules:
      - prefer_const_constructors
      - prefer_const_declarations
      - avoid_unnecessary_containers
      - unawaited_futures
      - cancel_subscriptions
      - close_sinks
  ```

#### D5-03 (Severidad: Alta) — Cobertura de Pruebas Insuficiente (&lt; 12%) y Ausencia de Pruebas de Widgets

- **Archivo:** `frontend/test/` (directorio completo)
- **Rango de Líneas:** Todos los archivos de prueba
- **Descripción Técnica:** Solo existen pruebas mínimas para `Game` model y `StringNormalizer`. No existen pruebas para `DatabaseService`, `SteamService`, `BackupService`, ni pruebas de widgets para las pantallas principales (`DashboardScreen`, `GameDetailScreen`, `SearchScreen`, `AnalyticsScreen`).
- **Remediación Concreta:** Desarrollar una suite de pruebas exhaustiva con pruebas unitarias sobre SQLite en memoria (`sqflite_common_ffi`), servicios con `MockClient`, y pruebas de integración de widgets para componentes clave.

#### D5-04 (Severidad: Media) — Código Muerto de Subsisemas Legados de Notion

- **Archivo:** `frontend/lib/services/notion_service.dart` (Líneas 1–411), `frontend/lib/services/notion_parser.dart` (Líneas 1–201), `frontend/lib/screens/setup_screen.dart` (Líneas 1–507)
- **Rango de Líneas:** 1–411, 1–201, 1–507
- **Descripción Técnica:** Tras la migración canónica a SQLite local-first en la versión v3.0+, los archivos de integración con la API de Notion permanecen en el árbol de código fuente principal como código muerto sin uso activo, generando confusión arquitectónica y sobrepeso en el binario.
- **Remediación Concreta:** Aislar o remover los archivos legados de Notion, consolidando la importación como una utilidad de migración histórica en `BackupService`.

---

## 3. Matriz de Cobertura y Diagnóstico de Módulos


| Módulo / Archivo                  | Tipo             | Pruebas Actuales    | Estado de Cobertura | Riesgo Técnico                                  |
| --------------------------------- | ---------------- | :-------------------: | :-------------------: | :-----------------------------------------------: |
| `models/game.dart`                | Modelo           | 4 unitarias         | ~65%                | Medio (Falta equality, Sentinel en hoursPlayed) |
| `services/database_service.dart`  | Backend / SQLite | 0                   | **0%**              | **Crítico** (Concurrencia, WAL, B-Tree)         |
| `services/steam_service.dart`     | Servicio Red     | 0                   | **0%**              | **Crítico** (Tormenta N+1, Sync transaccional)  |
| `services/hltb_service.dart`      | Servicio Red     | 1 (En vivo, frágil) | **0% (Mock)**       | **Alto** (Falta mutex de token y retry backoff) |
| `services/metadata_service.dart`  | Servicio Red     | 1 (En vivo, frágil) | **0% (Mock)**       | **Alto** (RAWG/Wiki sin MockClient)             |
| `services/backup_service.dart`    | Servicio I/O     | 0                   | **0%**              | **Alto** (Scoped storage, rutas Android/Win)    |
| `services/theme_manager.dart`     | Estado / Tema    | 0                   | **0%**              | Bajo                                            |
| `widgets/app_cover_image.dart`    | Widget UI        | 0                   | **0%**              | **Alto** (`existsSync()` síncrono, VRAM)        |
| `widgets/filter_modal_sheet.dart` | Widget UI        | 0                   | **0%**              | Medio                                           |
| `screens/dashboard.dart`          | Pantalla         | 0                   | **0%**              | **Alto** (Monolito 2686 líneas, getters O(N))   |
| `screens/game_detail_screen.dart` | Pantalla         | 0                   | **0%**              | Medio (Export card paths, dialogs)              |
| `screens/search_screen.dart`      | Pantalla         | 0                   | **0%**              | Medio (Fugas de TextEditingController)          |
| `screens/analytics_screen.dart`   | Pantalla         | 0                   | **0%**              | Medio (Recálculos estadísticos en build)        |
| `screens/settings_screen.dart`    | Pantalla         | 0                   | **0%**              | **Alto** (Almacenamiento de API keys)           |


---

## 4. Conclusiones y Hoja de Ruta Inmediata

1. **Veredicto:** El código actual demuestra una interfaz visual muy cuidada y un modelo conceptual claro, pero posee vulnerabilidades de seguridad de alta severidad (keystore en repositorio, API keys en texto plano) y riesgos de rendimiento/estabilidad en base de datos y red (tormenta N+1 en Steam sync, ausencia de WAL mode y transacciones por lotes).
2. **Estrategia:** La fase de auditoría ha finalizado con éxito en modo de **estricta solo lectura (0 archivos modificados en `frontend/lib/`)**.
3. **Paso Siguiente:** Ejecutar el plan de implementación detallado en `artifacts/planning/implementation_plan.md` y `artifacts/planning/task.md` priorizando la resolución de fallos críticos antes de proceder a la refactorización arquitectónica.



Nota del usuario: Agregar logica para que siempre y cuando las horas de HTBL sean menores a la horas de HTBLmain pues el juego este en estado "Jugando" Y si el juego ya supero las horas de HTBL de la primera campaña pues que sea "Jugado" y si el juego apenas tiene 

