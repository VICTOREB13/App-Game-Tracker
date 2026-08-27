---
tipo: task
proyecto: App_Game_Tracker
version: v3.0.5
estado: completado
fecha: 2026-08-27
agent: Project-Planner
tags: [tareas, checklist, v3.0.5, sqlite, steam-api, howlongtobeat, rawg-api, platform-selector, sentinel-pattern, open-source, devops, backend, frontend, quality-gate]
---

# ✅ Checklist Maestro de Tareas Técnicas (v3.0.5)

Documento operativo gestionado por **Project-Planner** para registrar la asignación y ejecución de tareas entre agentes especializados a lo largo de todas las iteraciones.

---

## 🗄️ 1. Infraestructura de Datos SQLite Local-First & Modelos (v3.0.0)
- [x] `(Backend-Architect)` Añadir dependencias SQLite (`sqflite`, `sqflite_common_ffi`, `path_provider`, `path`, `file_picker`, `uuid`) en `pubspec.yaml`.
- [x] `(Backend-Architect)` Crear singleton `DatabaseService` (`lib/services/database_service.dart`) con soporte dual FFI (Windows) y nativo (Android).
- [x] `(Backend-Architect)` Definir esquema DDL de tabla `games` con campos canónicos e índices B-Tree en `steam_id`, `status`, `platform` y `title` para consultas en < 2 ms.
- [x] `(Backend-Architect)` Refactorizar clase `Game` (`lib/models/game.dart`) con serialización `toSqliteMap()` y deserialización `fromSqliteMap()`.
- [x] `(Backend-Architect)` Implementar operaciones CRUD completas y comando de mantenimiento en caliente `vacuum()`.

---

## 🎮 2. Integración y Sincronización con Steam Web API (v3.0.0)
- [x] `(Backend-Architect)` Crear servicio `SteamService` (`lib/services/steam_service.dart`).
- [x] `(Backend-Architect)` Implementar consulta dual a Steam Web API: `GetOwnedGames` (biblioteca propia) y `GetRecentlyPlayedGames` (juegos de **Family Sharing**).
- [x] `(Backend-Architect)` Implementar resolución de Vanity URL a SteamID64 (`ISteamUser/ResolveVanityURL`).
- [x] `(Backend-Architect)` Implementar filtro de ruido de 30 minutos (`playtimeHours >= 0.5`).
- [x] `(Backend-Architect)` Implementar matching tri-fase: Steam ID $\rightarrow$ Nombre limpio $\rightarrow$ Similitud difusa con `StringNormalizer` ($> 0.90$).
- [x] `(Backend-Architect)` Implementar auto-culminación por HLTB al superar las horas de la historia principal.

---

## 🧹 3. Purga de Legado & Límites Defensivos de Memoria (v3.0.1)
- [x] `(Backend-Architect)` Eliminar definitivamente el getter heredado `notionPageId` en `Game`.
- [x] `(Frontend-UI)` Migrar todas las etiquetas Hero, `ValueKey` en animaciones Stagger y referencias de lista a `game.id`.
- [x] `(Backend-Architect)` Implementar límites defensivos de variables: títulos (255 chars), resúmenes (2000 chars), URLs (2048 chars), géneros (20x50 chars) y horas (0 a 99,999).

---

## ⏱️ 4. Servicio Nativo HowLongToBeat (`HltbService`) (v3.0.2)
- [x] `(Backend-Architect)` Crear `HltbService` (`lib/services/hltb_service.dart`) con cliente HTTP directo contra `/api/search/site/init` y `/api/search/site`.
- [x] `(Backend-Architect)` Implementar extracción y conversión de segundos a horas para Historia Principal y 100% Completista.
- [x] `(Backend-Architect)` Integrar gestión de tokens de seguridad (`x-auth-token`, `x-hp-key`, `x-hp-val`) y reintentos automáticos.
- [x] `(Frontend-UI)` Añadir botón interactivo **"Buscar en HLTB"** con indicador de carga en `GameDetailScreen`.
- [x] `(Frontend-UI)` Añadir acción masiva **"Buscar Metadatos HLTB en mi Biblioteca"** en `SettingsScreen` con reporte en diálogo modal.
- [x] `(Backend-Architect)` Integrar consulta de HLTB durante la sincronización de Steam para juegos sin estimación.

---

## 🌐 5. Géneros RAWG Ilimitados & Enlaces Oficiales de Wikipedia (v3.0.3)
- [x] `(Frontend-UI)` Remover filtros de lista cerrada en `SearchScreen` para capturar **todos** los géneros devueltos por RAWG.
- [x] `(Backend-Architect)` Reestructurar `MetadataService.searchWikipedia` con `Uri.https`, sanitización de símbolos (`™`, `®`, `©`) y cabecera oficial `User-Agent: GameTracker/3.0`.
- [x] `(Frontend-UI)` Automatizar asignación de enlace de Wikipedia al guardar juegos desde el buscador.
- [x] `(Backend-Architect)` Asignar géneros RAWG y enlaces de Wikipedia durante la sincronización con Steam.
- [x] `(Frontend-UI)` Añadir botón de acción rápida de Wikipedia (`Icons.travel_explore_rounded`) en `GameDetailScreen`.
- [x] `(Frontend-UI)` Añadir botón de acción masiva **"Sincronizar Géneros, Portadas y Wikipedia"** en `SettingsScreen`.

---

## 🎯 6. Selector Visual de Plataformas con Detección Automática (v3.0.4)
- [x] `(Frontend-UI)` Eliminar el dropdown vertical que desbordaba la pantalla en `_promptGameDetails`.
- [x] `(Backend-Architect)` Extraer las plataformas oficiales del juego desde `rawgGame['platforms']` y normalizarlas con `_canonicalPlatform`.
- [x] `(Frontend-UI)` Implementar selector basado en **Chips interactivos con logotipos de fabricantes** (`PlatformHelper`).
- [x] `(Frontend-UI)` Añadir botón conmutador **"+ Otras plataformas"** para acceder al catálogo global.
- [x] `(Frontend-UI)` Restringir altura máxima de menús desplegables (`menuMaxHeight: 220`) y reorganizar ergonómicamente el formulario.

---

## 🛠️ 7. CRUD Completo con Patrón Sentinel & Borrado de Enlaces (v3.0.5)
- [x] `(Backend-Architect)` Implementar el patrón `_sentinel` en `Game.copyWith` para soportar asignación explícita de `null` en propiedades opcionales (`link`, `coverUrl`, `summary`, `rating`).
- [x] `(Frontend-UI)` Añadir botón interactivo de borrado rápido (`Icons.clear_rounded`) en el campo de enlace de Wikipedia en `GameDetailScreen`.
- [x] `(Backend-Architect)` Validar que `DatabaseService.updateGame` guarde exitosamente valores `NULL` en la base de datos SQLite.
- [x] `(Frontend-UI)` Permitir restablecer la calificación a 'Sin calificar' (`NULL`).
- [x] `(Systems-Auditor)` Añadir prueba unitaria en `game_model_test.dart` validando el borrado de enlaces y portadas mediante `copyWith(link: null)`.

---

## 🚀 8. Seguridad, CI/CD Automatizado & Documentación Open Source
- [x] `(DevOps-Engineer)` Actualizar `README.md` con la versión final v3.0.5 y enlaces oficiales a [victorengineer.fyi](https://victorengineer.fyi).
- [x] `(DevOps-Engineer)` Proteger workflow `.github/workflows/sync-docs.yml` agregando `if: github.repository == 'VICTOREB13/App-Game-Tracker'`.
- [x] `(DevOps-Engineer)` Blindar `.gitignore` con exclusiones de bases de datos locales (`*.db`, `*.sqlite`), backups JSON y archivos `.env`.
- [x] `(DevOps-Engineer)` Verificar pipeline de releases `.github/workflows/release.yml` en tags (`v*`) para compilar Windows x64 ZIP y APK firmado permanente.
- [x] `(Project-Planner)` Actualizar todos los artefactos del proyecto al estado v3.0.5.
