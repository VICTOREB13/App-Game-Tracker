---
tipo: task
proyecto: App_Game_Tracker
version: v3.0.0
estado: completado
fecha: 2026-08-27
agent: Project-Planner
tags: [tareas, checklist, v3.0.0, sqlite, steam-api, games-py, cover-picker, rawg-api, open-source, devops, backend, frontend, quality-gate]
---

# ✅ Checklist de Tareas Técnicas: Migración a SQLite Local, Steam Sync & Portadas Híbridas (v3.0.0)

Documento operativo gestionado por **Project-Planner** para registrar la asignación y ejecución de tareas entre agentes especializados.

---

## 🗄️ 1. Infraestructura de Datos SQLite Local, Selector de Archivos & Normalización
- [x] `(Backend-Architect)` Añadir dependencias `sqflite: ^2.3.2`, `sqflite_common_ffi: ^2.3.2+1`, `path_provider: ^2.1.2`, `path: ^1.9.0`, `file_picker: ^8.0.0` y `uuid: ^4.3.3` a `pubspec.yaml`.
- [x] `(Backend-Architect)` Crear `StringNormalizer` (`lib/services/string_normalizer.dart`) replicando `limpiar_nombre(n)` de `games.py` y `similar(a, b)` con similitud difusa `>= 0.90`.
- [x] `(Backend-Architect)` Crear singleton `DatabaseService` (`lib/services/database_service.dart`) con detección de entorno FFI para Windows Desktop y nativo para Android.
- [x] `(Backend-Architect)` Definir esquema DDL de tabla `games` con campos canónicos (`id`, `title`, `cover_url`, `status`, `platform`, `hours_played`, `genres`, `rating`, `hltb_main`, `hltb_completionist`, `summary`, `link`, `start_date`, `completed_date`, `steam_id`, `created_at`, `updated_at`).
- [x] `(Backend-Architect)` Crear índices B-Tree en `steam_id`, `status`, `platform` y `title` para búsquedas en < 2 ms.
- [x] `(Backend-Architect)` Refactorizar clase `Game` (`lib/models/game.dart`) reemplazando `notionPageId` por `id` (UUID) e implementando `toSqliteMap()`, `fromSqliteMap()`, `toJson()`, `fromJson()` y getter retrocompatible `notionPageId`.
- [x] `(Backend-Architect)` Implementar métodos CRUD completos (`getAllGames`, `getGameById`, `insertGame`, `updateGame`, `deleteGame`, `batchUpsertGames`, `getGameCount`, `getTotalHours`, `vacuum`).

---

## 🎮 2. Portabilidad de Lógica de Steam de `games.py` a Dart
- [x] `(Backend-Architect)` Crear servicio `SteamService` (`lib/services/steam_service.dart`).
- [x] `(Backend-Architect)` Implementar consulta dual a Steam Web API: `GetOwnedGames` (juegos propios) y `GetRecentlyPlayedGames` (juegos de **Family Sharing** y horas recientes).
- [x] `(Backend-Architect)` Implementar método `resolveVanityUrl(apiKey, vanityUrl)` para convertir nombres de usuario personalizados en SteamID64 (`ISteamUser/ResolveVanityURL`).
- [x] `(Backend-Architect)` Implementar el filtro estricto de 30 minutos (`playtimeHours >= 0.5`) de `games.py`.
- [x] `(Backend-Architect)` Implementar el algoritmo de emparejamiento tri-fase:
  - Intento 1: Coincidencia por `steam_id` indexado.
  - Intento 2: Coincidencia exacta por nombre limpio (`StringNormalizer.cleanTitle`).
  - Intento 3: Coincidencia por similitud difusa (`similarity > 0.90`).
- [x] `(Backend-Architect)` Implementar reglas de creación automática: estado `"Jugado"` si horas > 1h, sino `"Por Jugar"`, plataforma `"PC"`, y `fecha_inicio = hoy` si horas > 0.
- [x] `(Backend-Architect)` Implementar reglas de actualización y **Auto-Culminación por HLTB**: si `horas >= hltb_main`, cambiar estado a `"Jugado"`, registrar `fecha_culminacion = hoy`, y proteger contra alteraciones si ya estaba en `ESTADOS_FINALES`.
- [x] `(Backend-Architect)` Retornar reporte de sincronización estructurado (juegos actualizados, creados, Family Sharing y auto-culminados).

---

## 🔍 3. Servicio de Enriquecimiento de Metadatos (`rellenar_metadata`)
- [x] `(Backend-Architect)` Crear servicio `MetadataService` (`lib/services/metadata_service.dart`).
- [x] `(Backend-Architect)` Implementar consulta a RAWG API (`search`, `page_size: 1`) para extraer carátulas en HD (`background_image`) y géneros principales cuando falten en un juego.
- [x] `(Backend-Architect)` Implementar consulta a Wikipedia API (`es.wikipedia.org` y `en.wikipedia.org`) para auto-rellenar el enlace de referencia canónico.
- [x] `(Backend-Architect)` Integrar consulta de tiempos HLTB (Main Story y Completionist).

---

## 🎨 4. Capa de Presentación & UI/UX (Frontend - Preservación Visual & Portadas Híbridas)
- [x] `(Frontend-UI)` Preservar al 100% el diseño visual, componentes, colores Zinc/Crimson, tipografías y vistas existentes sin alteraciones estéticas.
- [x] `(Frontend-UI)` Modificar `main.dart` para inicializar `DatabaseService` y arrancar directamente en `DashboardScreen` con 0 ms de espera.
- [x] `(Frontend-UI)` Conectar `DashboardScreen` con `DatabaseService.getAllGames()`, eliminando dependencias de red de Notion.
- [x] `(Frontend-UI)` Reemplazar botón de sincronización en AppBar por botón animado de **"Sincronizar Steam"** manteniendo la misma posición y estilo visual.
- [x] `(Frontend-UI)` Crear widget universal `AppCoverImage` (`lib/widgets/app_cover_image.dart`) que detecta y renderiza tanto URLs web (`CachedNetworkImage`) como imágenes locales (`Image.file`).
- [x] `(Frontend-UI)` Modificar `GameDetailScreen` para implementar el selector híbrido de portadas:
  - Campo de texto para pegar URL web directa (`https://...`).
  - Botón para elegir archivo desde la galería de fotos en Android o explorador de Windows (`file_picker`), con copia persistente en `covers/cover_{id}_{timestamp}.png`.
  - Persistencia de guardado y eliminación en `DatabaseService`.
- [x] `(Frontend-UI)` Adaptar `SearchScreen` para insertar juegos directamente en SQLite local al seleccionarlos desde el buscador de RAWG API.
- [x] `(Frontend-UI)` Adaptar `AnalyticsScreen` para calcular métricas directamente de SQLite.
- [x] `(Frontend-UI)` Rediseñar `SettingsScreen` conservando la estética actual:
  - Panel de control de **Base de Datos Local (SQLite)** con conteo de juegos, horas totales, optimización (Vacuum) y ruta del archivo `.db`.
  - Panel de **Integración Steam** con inputs para API Key y SteamID, resolución de Vanity URL, botón de prueba y botón de sincronización directa.
  - Panel de **Búsqueda RAWG** con API Key.
  - Panel de **Copia de Seguridad JSON** con selector de explorador y botón de carga de dataset de prueba.
  - Sección oficial de autoría **Victor Engineer** con enlace canónico a `https://victorengineer.fyi`.

---

## 💾 5. Servicio de Respaldo, Portabilidad JSON & Dataset de Prueba
- [x] `(Backend-Architect)` Crear dataset de prueba `sample_games_library.json` con catálogo variado y realista de juegos para importación inmediata.
- [x] `(Backend-Architect)` Actualizar `BackupService` (`lib/services/backup_service.dart`) para exportar directamente desde SQLite a un archivo JSON limpio y legible en Descargas.
- [x] `(Backend-Architect)` Implementar importador híbrido en `BackupService` capaz de restaurar tanto el nuevo formato JSON v3.0 como copias de seguridad previas de Notion (v2.x).

---

## 🚀 6. Publicación Open Source, Documentación & CI/CD
- [x] `(DevOps-Engineer)` Redactar `README.md` maestro de nivel profesional en la raíz del repositorio con identidad de marca personal Victor Engineer ([victorengineer.fyi](https://victorengineer.fyi)), badges, arquitectura y guía paso a paso para obtener claves de RAWG y Steam.
- [x] `(DevOps-Engineer)` Crear archivo `LICENSE` con la licencia de código abierto MIT.
- [x] `(DevOps-Engineer)` Crear workflow `.github/workflows/release.yml` con activación **exclusiva en tags (`v*`)** (sin ejecutarse en push a `main`) para compilar Windows x64 ZIP y APK Android firmado.
- [x] `(DevOps-Engineer)` Desactivar el antiguo workflow `games.yml`.

---

## 📋 7. Auditoría de Calidad & Quality Gate (Audit)
- [x] `(Systems-Auditor)` Pruebas unitarias implementadas para `StringNormalizer` (`string_normalizer_test.dart`) y modelo `Game` (`game_model_test.dart`).
- [x] `(Systems-Auditor)` Validar que las transacciones y consultas SQLite se ejecuten en < 5 ms en Windows y Android.
- [x] `(Systems-Auditor)` Validar renderizado correcto tanto de portadas remotas como de fotos locales de la galería en `DashboardScreen` y `GameDetailScreen` con `AppCoverImage`.
- [x] `(Systems-Auditor)` Validar precisión de `StringNormalizer` y fuzzy matching con juegos con nombres complejos.
- [x] `(Systems-Auditor)` Validar consistencia y robustez de la importación y exportación de archivos JSON.
- [x] `(Systems-Auditor)` Generar y archivar el reporte formal de auditoría (`audit_report.md`) con aprobación para el pase a producción.
