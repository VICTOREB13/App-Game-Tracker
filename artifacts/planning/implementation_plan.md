---
tipo: plan
proyecto: App_Game_Tracker
version: v3.0.0
estado: en_planificacion
fecha: 2026-08-27
agent: Project-Planner
tags: [plan, v3.0.0, sqlite-local, offline-first, steam-api, games-py, cover-picker, rawg-api, open-source, github-releases, backup-json, victor-engineer]
---

# 📋 Plan de Implementación Maestro v3.0.0: Portabilidad 100% de `games.py` a SQLite Local, Steam Web API, Portadas Híbridas & Open Source

Documento maestro orquestado por el rol **Project-Planner** que establece la migración arquitectónica para transformar el proyecto en una aplicación **100% Local-First** con **SQLite**, replicando al 100% la lógica de sincronización, normalización, matching difuso, auto-culminación HLTB y enriquecimiento de metadatos de [`games.py`](file:///c:/Users/vmesp/Documents/Cositas/App-Game-Tracker/games.py) directamente en Flutter/Dart, con selector híbrido de portadas (URL web o archivos de galería local), preparando el repositorio para distribución pública Open Source bajo la marca personal **Victor Engineer** ([victorengineer.fyi](https://victorengineer.fyi)).

---

## 🎯 Directrices Clave de la Versión v3.0.0

1. **Preservación Visual Total:** **Cero modificaciones visuales o de diseño.** Toda la interfaz actual (Grid cinematográfico, Lista compacta, filtros, tema Obsidian Zinc y Crisp Zinc, tarjetas de analíticas, métricas y tipografías) se conserva en su estado actual. Solo se sustituye el motor interno de datos (Notion $\rightarrow$ SQLite local).
2. **Dominio Oficial:** Enlace canónico a **`https://victorengineer.fyi`**.
3. **Gestión Dual de Portadas (URL Web + Galería / Archivo Local):**
   - **Opción A (URL de Internet):** Pegar cualquier enlace web directo de imagen sin restricciones de AWS S3 ni errores HTTP 400.
   - **Opción B (Galería Local):** Botón para seleccionar una imagen desde la galería en Android o explorador de Windows (`file_picker`), con copia persistente en `app_documents/covers/{id}.png`.
   - **Renderizado Híbrido:** `CachedNetworkImage` si es HTTP/HTTPS; `Image.file` si es ruta local.
4. **Lógica de `games.py` Preservada al 100%:**
   - Detección dual de Steam (`GetOwnedGames` + `GetRecentlyPlayedGames` para **Family Sharing**).
   - Filtro de umbral de 30 minutos (`playtimeHours >= 0.5`).
   - Normalizador de títulos con purga de caracteres `['™', '®', '©', ':', '.', ',', '!', '?', '-', '_', '(', ')']`.
   - Matching difuso (fuzzy ratio > 0.90) y matching exacto por Steam ID o nombre limpio.
   - Auto-culminación automática a "Jugado" con fecha al alcanzar las horas de HowLongToBeat.
   - Enriquecimiento con RAWG API y Wikipedia API.
5. **CI/CD de Releases Exclusivo para Tags:** El pipeline `.github/workflows/release.yml` solo se ejecutará cuando se cree un tag (`v*`), nunca en push a la rama `main`.
6. **Dataset de Prueba JSON:** Archivo [`sample_games_library.json`](file:///c:/Users/vmesp/Documents/Cositas/App-Game-Tracker/sample_games_library.json) disponible en la raíz con 12 títulos de prueba listos para importar.

---

## 🏗️ Desglose de Tareas por Agentes

- **`Project-Planner`**: Orquestación y gobernanza de artefactos Obsidian (`project_overview.md`, `architecture.md`, `api_spec.md`, `task.md`, `changelog_v1.md`).
- **`Backend-Architect`**:
  - `pubspec.yaml`: Dependencias SQLite (`sqflite`, `sqflite_common_ffi`, `path_provider`, `path`) y `file_picker: ^8.0.0`.
  - `string_normalizer.dart`: Purga de símbolos y cálculo de similitud difusa > 0.90.
  - `database_service.dart`: Singleton SQLite DDL, tabla `games`, índices B-Tree y operaciones CRUD.
  - `steam_service.dart`: Motor de sincronización dual (propios + Family Sharing), filtro 30 min, matching tri-fase y auto-culminación HLTB.
  - `metadata_service.dart`: Consultas a RAWG API y Wikipedia API (`es`/`en`).
  - `game.dart` y `backup_service.dart`: Desacoplamiento de Notion, métodos SQLite y compatibilidad con JSON legacy.
- **`Frontend-UI`**:
  - Preservación visual 100% intacta.
  - Conexión de `DashboardScreen` con `DatabaseService` y botón de sincronización Steam en el AppBar.
  - Actualización de `GameDetailScreen` con selector dual de portadas (pegar URL o elegir foto de galería).
  - Renderizado híbrido de imágenes (`FileImage` o `CachedNetworkImage`).
  - Actualización de `SearchScreen` para guardar en SQLite local tras consultar RAWG.
  - Actualización de `SettingsScreen` con paneles de Steam, SQLite, RAWG y enlace canónico a `https://victorengineer.fyi`.
- **`DevOps-Engineer`**:
  - Redacción de `README.md` maestro bilingüe con marca personal Victor Engineer ([victorengineer.fyi](https://victorengineer.fyi)), badges y tutoriales de API Keys.
  - Creación de archivo `LICENSE` (MIT).
  - Creación de `.github/workflows/release.yml` con activación exclusiva en tags (`v*`) para compilar Windows x64 ZIP y APK Android firmado.
  - Archivar `games.yml`.
- **`Systems-Auditor`**:
  - Validación de análisis estático (`flutter analyze`).
  - Pruebas de rendimiento en SQLite (< 5 ms por consulta).
  - Verificación de precisión del emparejamiento difuso, selección de archivos locales y reporte formal `audit_report.md`.
