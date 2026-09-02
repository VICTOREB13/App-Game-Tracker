# 🚀 Plan de Implementación Estructurado — Remediación y Evolución Técnica (v3.1.0)

**Proyecto:** App Game Tracker  
**Versión Objetivo:** v3.1.0  
**Fecha de Planificación:** 2026-08-29  
**Metodología:** Prototipado Evolutivo por Fases Priorizadas (Teamwork Orchestration)  
**Roles Asignados:** `Backend-Architect`, `Frontend-UI`, `Systems-Auditor`, `DevOps-Engineer`  

---

## 1. Visión General y Estrategia de Ejecución

El presente plan de implementación define la hoja de ruta técnica para resolver integralmente los 25 hallazgos identificados en la auditoría técnica del código fuente (`artifacts/audit_reports/audit_report_codebase.md`). La estrategia se organiza en **4 fases progresivas y estrictamente ordenadas por prioridad de riesgo**:

1. **Fase 1: Seguridad Crítica, Gestión de Secretos y Quality Gate CI/CD** (Prioridad Máxima - Bloqueante de Integridad).
2. **Fase 2: Concurrencia SQLite, Persistencia Atómica y Resiliencia de Red** (Prioridad Alta - Estabilidad del Core).
3. **Fase 3: Optimización de Renderizado 60 FPS, Memoria y Modularización UI** (Prioridad Alta/Media - Ergonomía y Rendimiento).
4. **Fase 4: Cobertura Exhaustiva de Pruebas Automatizadas y Aprobación de Release** (Prioridad Media - Calidad y Certificación).

---

## 2. Desglose de Fases de Implementación

---

### 🛡️ Fase 1: Seguridad Crítica, Gestión de Secretos y Quality Gate CI/CD
**Objetivo:** Eliminar de inmediato las vulnerabilidades de seguridad críticas en el repositorio y código, y habilitar la infraestructura de análisis estático y testing continuo.

#### 1.1 Remediación de Keystore de Firma en Repositorio
- **Problema:** `frontend/assets/keystore/release.keystore` está en el control de versiones y forzado en `.gitignore:43`.
- **Impacto:** Compromiso de la clave privada de firma de Android.
- **Solución Técnica:**
  1. Remover el archivo de clave del árbol de git y actualizar `.gitignore` (`*.keystore`, `*.jks`).
  2. Configurar la inyección del keystore en CI/CD mediante secreto Base64 (`ANDROID_KEYSTORE_BASE64`).
- **Rol Asignado:** `DevOps-Engineer`
- **Criterio de Verificación:** `git status --ignored` confirma que los archivos `.keystore` están ignorados; CI/CD decodifica y firma APKs con éxito desde secrets.

#### 1.2 Almacenamiento Seguro de Claves de API con `flutter_secure_storage`
- **Problema:** Steam API Key, RAWG Key y Notion Token se guardan en texto plano en `SharedPreferences` (`settings_screen.dart`, `setup_screen.dart`).
- **Impacto:** Exposición de tokens en disco en Android y Windows.
- **Solución Técnica:**
  1. Añadir `flutter_secure_storage: ^9.2.2` a `pubspec.yaml`.
  2. Implementar `SecureStorageService` para encapsular la lectura/escritura cifrada de credenciales usando Android Keystore y Windows DPAPI.
  3. Migrar transparentemente las claves existentes desde `SharedPreferences` a `SecureStorageService` al primer arranque.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Pruebas unitarias de almacenamiento y verificación de que `SharedPreferences` no contiene claves de API.

#### 1.3 Configuración de Linter Estricto `analysis_options.yaml`
- **Problema:** Linter inactivo por ausencia del archivo de configuración.
- **Impacto:** Deuda técnica no detectada en compilación.
- **Solución Técnica:** Crear `frontend/analysis_options.yaml` con reglas estrictas de tipos, inmutabilidad (`prefer_const_constructors`), constructores const y control de futuros no esperados (`unawaited_futures`).
- **Rol Asignado:** `Systems-Auditor`
- **Criterio de Verificación:** `flutter analyze` se ejecuta sobre todo el código fuente reportando 0 errores.

#### 1.4 Pipeline de Quality Gate en CI/CD (`ci.yml`)
- **Problema:** Workflows actuales compilan sin ejecutar pruebas ni análisis estático.
- **Impacto:** Riesgo de publicar releases con fallos funcionales o regresiones.
- **Solución Técnica:** Crear `.github/workflows/ci.yml` activado en `push` y `pull_request` con `flutter analyze --fatal-infos` y `flutter test --coverage`.
- **Rol Asignado:** `DevOps-Engineer`
- **Criterio de Verificación:** Ejecución exitosa del workflow en GitHub Actions bloqueando PRs con advertencias.

---

### ⚡ Fase 2: Concurrencia SQLite, Persistencia Atómica y Resiliencia de Red
**Objetivo:** Garantizar la integridad transaccional del motor SQLite, prevenir colisiones de concurrencia y blindar el consumo de APIs externas contra tormentas de red y rate limits.

#### 2.1 Protección de Inicialización Asíncrona de SQLite
- **Problema:** `DatabaseService.instance.database` sin cerrojo genera aperturas duplicadas (`database is locked`) en Desktop.
- **Impacto:** Fallos intermitentes en arranque y tareas de fondo.
- **Solución Técnica:** Implementar memoización de inicialización asíncrona mediante `Future<Database>? _initFuture` en `DatabaseService`.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Prueba de estrés de 50 accesos concurrentes paralelos a `database` retornando la misma instancia sin excepciones.

#### 2.2 Activación de WAL Mode, Integridad Referencial e Índices B-Tree
- **Problema:** Bloqueo exclusivo en escrituras, ordenamiento en RAM por falta de índices con `COLLATE NOCASE` y ausencia de índice en `updated_at`.
- **Impacto:** Congelamiento de UI en sincronización masiva y escaneos de tabla completos.
- **Solución Técnica:**
  1. Configurar `onConfigure` con `PRAGMA journal_mode = WAL;`, `foreign_keys = ON;`, `synchronous = NORMAL;`.
  2. Crear índices B-Tree optimizados: `idx_games_title_nocase`, `idx_games_updated_at`, `idx_games_hours_played`, `idx_games_rating`, `idx_games_status_updated`.
  3. Implementar controlador de migraciones `onUpgrade` en `DatabaseService`.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** `EXPLAIN QUERY PLAN` en consultas de ordenamiento y filtrado confirmando uso de índices sin `SCAN TABLE`.

#### 2.3 Desacoplamiento de Sincronización de Steam en Dos Fases
- **Problema:** Bucle N+1 secuencial ejecutando 3 llamadas HTTP y 1 `fsync` en disco por cada juego de Steam.
- **Impacto:** Bloqueos de más de 30 segundos, rate limiting (HTTP 429) y saturación de sockets.
- **Solución Técnica:**
  1. **Fase 1 (Core Inmediato):** Obtener biblioteca de Steam e insertar/actualizar todos los títulos en una sola transacción atómica por lotes (`batchUpsertGames`) con `db.transaction(...)` (< 1 seg).
  2. **Fase 2 (Enriquecimiento en Segundo Plano):** Cola asíncrona con pool de concurrencia máxima (2 workers) y delay de 300 ms entre peticiones para HLTB, Wikipedia y RAWG.
  3. Emitir progreso en tiempo real mediante `Stream<SyncProgress>` con soporte de `CancellationToken`.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Sincronización de 300 juegos ejecutando persistencia en < 500 ms y enriquecimiento progresivo sin errores HTTP 429.

#### 2.4 Infraestructura `ResilientHttpClient` y Codificación Segura de URLs
- **Problema:** Falta de pool persistente de conexiones, ausencia de reintentos con backoff exponencial e interpolación insegura de strings en URLs.
- **Impacto:** Malformación de URLs y fallos ante errores transitorios de red.
- **Solución Técnica:**
  1. Crear `ResilientHttpClient` con pool de `http.Client`, timeouts y backoff exponencial ante HTTP 429/500.
  2. Reemplazar toda interpolación de strings por `Uri.https()` con mapas tipados de parámetros.
  3. Proteger `HltbService._ensureAuthToken()` con mutex de concurrencia.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Pruebas unitarias con simulación de errores 429/503 validando reintentos automáticos y codificación limpia de caracteres especiales (`&`, `+`, espacios).

#### 2.5 Corrección de Backup y Rutas Multiplataforma (Scoped Storage)
- **Problema:** Rutas fijas `/storage/emulated/0/Download` violan Scoped Storage en Android; fallback a `Directory.current` falla en Windows.
- **Impacto:** Excepciones de permisos denegados al exportar/importar respaldos.
- **Solución Técnica:** Migrar a `path_provider` (`getDownloadsDirectory()`) e integrar `file_picker` para selección nativa de archivos.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Exportación e importación exitosa en emulador Android 14 y Windows Desktop.

#### 2.6 Perfeccionamiento del Patrón Sentinel y Preservación de Fechas en `Game`
- **Problema:** `copyWith` no limpia `hoursPlayed` con null; `toSqliteMap()` sobrescribe `updated_at` destruyendo marcas históricas.
- **Impacto:** Inconsistencias al editar y pérdida de fechas originales en respaldos.
- **Solución Técnica:** Aplicar `_sentinel` a todos los campos en `copyWith` y preservar `updatedAt` existente en `toSqliteMap()`.
- **Rol Asignado:** `Backend-Architect`
- **Criterio de Verificación:** Pruebas unitarias en `game_model_test.dart` verificando reseteo a null y preservación de fechas.

---

### 🎨 Fase 3: Optimización de Renderizado 60 FPS, Memoria y Modularización UI
**Objetivo:** Eliminar jank en el hilo de interfaz de usuario, optimizar el consumo de VRAM de carátulas y descomponer la pantalla monolítica del Dashboard.

#### 3.1 Optimización I/O y Caché de Memoria en `AppCoverImage`
- **Problema:** `File.existsSync()` bloqueante en `build()` y falta de `memCacheWidth` en `CachedNetworkImage`.
- **Impacto:** Caídas de frames en scroll y sobreconsumo de VRAM/RAM (hasta 8 MB por carátula).
- **Solución Técnica:**
  1. Eliminar `existsSync()` síncrono; cargar directamente mediante `Image.file` con `errorBuilder`.
  2. Fijar `memCacheWidth: 400` y `memCacheHeight: 600` en `CachedNetworkImage` y `cacheWidth: 400` en `Image.file`.
- **Rol Asignado:** `Frontend-UI`
- **Criterio de Verificación:** Scroll continuo en catálogo de 500 juegos manteniendo 60 FPS estables y consumo de RAM < 120 MB.

#### 3.2 Delegación de Filtrado y Ordenamiento a SQLite desde la UI
- **Problema:** `DashboardScreen` y `AnalyticsScreen` cargan toda la tabla en RAM y filtran/calculan en Dart en cada frame.
- **Impacto:** Desperdicio de CPU y GC pauses en listas grandes.
- **Solución Técnica:**
  1. Conectar los filtros y ordenamientos de `DashboardScreen` directamente a consultas SQL con `LIMIT / OFFSET`.
  2. Cachear opciones de filtros en variables de estado actualizables únicamente ante eventos de datos.
  3. Crear métodos de agregación SQL dedicados en `DatabaseService` para `AnalyticsScreen`.
- **Rol Asignado:** `Frontend-UI` / `Backend-Architect`
- **Criterio de Verificación:** Tiempo de carga y filtrado < 10 ms para cualquier combinación de filtros.

#### 3.3 Descomposición de la Pantalla Monolítica `DashboardScreen` (2,686 líneas)
- **Problema:** "God Class" con acoplamiento severo entre UI, controladores, animaciones y lógica de negocio.
- **Impacto:** Dificultad de mantenimiento y testabilidad nula de widgets.
- **Solución Técnica:** Modularizar en componentes independientes bajo `frontend/lib/widgets/dashboard/`:
  - `game_card_grid.dart`: Tarjeta de cuadrícula con hover interactivo.
  - `game_card_list.dart`: Fila de vista compacta con acciones rápidas (`+1h`).
  - `hero_spotlight_card.dart`: Tarjeta destacada con `RepaintBoundary` en el pulso de actividad.
  - `pagination_control_bar.dart`: Barra de control de paginación desacoplada.
  - `steam_sync_dialog.dart`: Diálogo de progreso de sincronización reactivo.
- **Rol Asignado:** `Frontend-UI`
- **Criterio de Verificación:** `dashboard.dart` reducido a < 450 líneas actuando puramente como coordinador de pantalla.

#### 3.4 Prevención de Fugas de Memoria en Diálogos y Limpieza de Código Muerto
- **Problema:** `TextEditingController`s instanciados en diálogos sin `dispose()`; archivos legados de Notion sin uso.
- **Impacto:** Fugas de memoria progresivas y confusión arquitectónica.
- **Solución Técnica:**
  1. Modularizar los diálogos en `StatefulWidget`s con `dispose()` formal.
  2. Eliminar o aislar los archivos legados de Notion (`notion_service.dart`, `notion_parser.dart`, `setup_screen.dart`).
- **Rol Asignado:** `Frontend-UI` / `Systems-Auditor`
- **Criterio de Verificación:** Inspección de perfiles de memoria en DevTools confirmando 0 fugas de controladores tras abrir y cerrar diálogos 20 veces.

---

### 🧪 Fase 4: Cobertura Exhaustiva de Pruebas Automatizadas y Quality Gate Final
**Objetivo:** Elevar la cobertura de pruebas de < 12% a > 80% con pruebas unitarias deterministas y pruebas de integración de widgets.

#### 4.1 Pruebas Unitarias Deterministas de Red (Mocks HTTP)
- **Problema:** Pruebas actuales de HLTB y Wikipedia hacen peticiones reales por internet.
- **Impacto:** Tests frágiles y falsos positivos.
- **Solución Técnica:** Implementar fixtures JSON y pruebas unitarias con `MockClient` para `SteamService`, `HltbService`, `MetadataService` simulando respuestas 200, 404, 429, 500 y timeouts.
- **Rol Asignado:** `Systems-Auditor`
- **Criterio de Verificación:** 100% de las pruebas de red se ejecutan en modo offline en < 2 segundos.

#### 4.2 Pruebas Unitarias del Motor SQLite y Persistencia
- **Problema:** 0% de pruebas sobre `DatabaseService` y `BackupService`.
- **Impacto:** Riesgo de regresión en migraciones, transacciones y filtros.
- **Solución Técnica:** Escribir suite de pruebas unitarias sobre SQLite en memoria (`sqflite_common_ffi`) cubriendo:
  - CRUD completo y transacciones por lotes (`batchUpsertGames`).
  - Ordenamientos por colación NOCASE, updated_at, rating y filtros combinados.
  - Concurrencia multihilo y transacciones atómicas.
  - Exportación e importación de respaldos JSON.
- **Rol Asignado:** `Systems-Auditor` / `Backend-Architect`
- **Criterio de Verificación:** `flutter test test/database_service_test.dart test/backup_service_test.dart` pasando al 100%.

#### 4.3 Pruebas de Widgets y UI
- **Problema:** 0% de pruebas sobre widgets y pantallas.
- **Impacto:** Riesgo de desbordamientos visuales o fallos en interacciones.
- **Solución Técnica:** Implementar pruebas de widgets para `AppCoverImage`, `GameCardGrid`, `FilterModalSheet`, `DashboardScreen` y `GameDetailScreen`.
- **Rol Asignado:** `Systems-Auditor` / `Frontend-UI`
- **Criterio de Verificación:** Pruebas de widgets verificando renderizado, interacciones de usuario y ausencia de excepciones en el árbol de renderizado.

#### 4.4 Auditoría de Quality Gate y Certificación de Release v3.1.0
- **Problema:** Requerimiento de certificación previa a la publicación.
- **Impacto:** Garantía de calidad para el usuario final y DevOps.
- **Solución Técnica:** Ejecutar auditoría integral de Quality Gate (`artifacts/audit_reports/audit_report.md` con veredicto `Status: PASS`).
- **Rol Asignado:** `Systems-Auditor` / `DevOps-Engineer`
- **Criterio de Verificación:** `flutter analyze` con 0 errores y 100% de pruebas pasando en CI/CD.

---

## 3. Matriz de Responsabilidades y Asignación de Roles

| Especialidad | Tareas Clave Asignadas | Artefactos Principales |
|---|---|---|
| 🛠️ **Backend-Architect** | `SecureStorageService`, concurrencia SQLite, WAL mode, B-Tree indexes, `batchUpsertGames`, `ResilientHttpClient`, Scoped Storage backup, Sentinel copyWith. | `database_service.dart`, `steam_service.dart`, `hltb_service.dart`, `metadata_service.dart`, `backup_service.dart`, `game.dart` |
| 🎨 **Frontend-UI** | Optimización `AppCoverImage` (memCache/I/O), modularización de `DashboardScreen`, filtros SQL en UI, prevención de fugas de memoria en diálogos, `RepaintBoundary`. | `app_cover_image.dart`, `dashboard.dart`, `widgets/dashboard/`, `game_detail_screen.dart`, `analytics_screen.dart` |
| 🛡️ **Systems-Auditor** | Configuración `analysis_options.yaml`, suite de pruebas unitarias SQLite en memoria, tests de red mockeados (`MockClient`), tests de widgets, Quality Gate report. | `analysis_options.yaml`, `test/*.dart`, `artifacts/audit_reports/audit_report.md` |
| ⚙️ **DevOps-Engineer** | Remoción de keystore en git, configuración de secretos en CI/CD, creación de workflow `ci.yml`, estandarización de versiones de Flutter en CI/CD. | `.gitignore`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` |
